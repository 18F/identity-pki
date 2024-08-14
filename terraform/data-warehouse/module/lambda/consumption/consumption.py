import time
import csv
import boto3
from pathlib import Path
from typing import List
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)


class ConsumptionBase:
    def __init__(self, schema_name: str, refresh_table: bool = False):
        self.schema_name = schema_name
        self.refresh_table = refresh_table

    def table_selection(self, key: str, temporary_table: bool = False):
        # Abstract method to be implemented by the child class
        raise NotImplementedError

    def create_tables_statement(self):
        # This create tables function will be deprecated in the future
        sql_statement_file = Path(__file__).parent.joinpath(
            f"{self.schema_name}_schema.sql"
        )
        with open(sql_statement_file, "r") as file:
            statement = file.read().strip()
        logger.info(statement)
        return statement

    def truncate_target_table_statement(self, key: str):
        target_table = self.table_selection(key)
        statement = f"TRUNCATE TABLE {target_table};"
        logger.info(statement)
        return statement

    def temp_table_statement(self, key: str):
        temp_table = self.table_selection(key, True)
        target_table = self.table_selection(key)
        statement = f"CREATE TEMP TABLE {temp_table}(LIKE {target_table});"
        logger.info(statement)
        return statement

    def get_column_headers(
        self,
        s3_client,
        bucket: str,
        key: str,
    ):
        csv_file = s3_client.get_object(Bucket=bucket, Key=key, Range="bytes=0-4096")
        csv_content = csv_file["Body"].read().decode("utf-8")

        # Get the first row of the CSV file which is the header
        csv_reader = csv.reader(csv_content.splitlines())
        column_list = next(csv_reader)
        return column_list

    def copy_statement(
        self,
        bucket: str,
        key: str,
        iam_role: str,
        column_list: str,
        temporary_table: bool = False,
    ):
        column_string = f"({', '.join(column_list)})"
        target_table = self.table_selection(key, temporary_table)
        statement = f"""
        COPY {target_table} {column_string}
        FROM 's3://{bucket}/{key}'
        IAM_ROLE '{iam_role}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;
        """.strip()
        print(statement)
        return statement

    def refresh_statement(self, bucket: str, key: str, iam_role: str):
        statement = f"""
        BEGIN;
        {self.truncate_target_table_statement(key)}
        {self.copy_statement(bucket, key, iam_role, False)}
        COMMIT;
        """.strip()
        logger.info(statement)
        return statement

    def merge_statement(
        self,
        bucket: str,
        key: str,
        iam_role: str,
        column_list: str,
        merge_keys: List[str] = ["id"],
    ):
        temp_table = self.table_selection(key, True)
        target_table = self.table_selection(key)
        merge_clause = " AND ".join(
            [f"{target_table}.{key} = {temp_table}.{key}" for key in merge_keys]
        )
        statement = f"""
        BEGIN;
        {self.temp_table_statement(key).strip()}
        {self.copy_statement(bucket, key, iam_role, column_list, True).strip()}
        MERGE INTO {target_table} USING {temp_table}
        ON {merge_clause} REMOVE DUPLICATES;
        COMMIT;
        """.strip()
        logger.info(statement)
        return statement

    def wait_for_completion(
        self, redshift_client, statement_id: str, started_means_done: bool
    ):
        """
        :param bool started_means_done: the moto library creates statements in
            "STARTED" mode and they do not transition, so enabling this option lets
            us prevent infinite loops when stubbing out AWS
        """
        while True:
            describe_statement = redshift_client.describe_statement(Id=statement_id)

            if describe_statement["Status"] == "FINISHED":
                break
            elif describe_statement["Status"] == "ABORTED":
                break
            elif describe_statement["Status"] == "STARTED" and started_means_done:
                break
            elif describe_statement["Status"] == "FAILED":
                raise Exception(describe_statement["Error"])
            else:
                logger.info("Sleeping")
                time.sleep(10)

        return describe_statement

    def execute_sql_statement(
        self,
        redshift_client,
        sql_statement: str,
        cluster_name: str,
        started_means_done: bool,
    ):
        response = redshift_client.execute_statement(
            Database="analytics",
            Sql=sql_statement,
            ClusterIdentifier=cluster_name,
        )
        logger.info(response)

        status = self.wait_for_completion(
            redshift_client, response["Id"], started_means_done
        )
        logger.info(status)


class IdpConsumption(ConsumptionBase):
    def __init__(self):
        super().__init__("idp", True)

    def table_selection(self, key: str, temporary_table: bool = False):
        _public, table, *_rest = key.split("/")
        if temporary_table:
            return f"{self.schema_name}_{table}_temp"
        return f"{self.schema_name}.{table}"


class LogConsumption(ConsumptionBase):
    def __init__(self):
        super().__init__("logs")

    def map_log_stream_to_table(self, key: str):
        # Check if the file/log stream should be processed for the associated log group
        # and return the table name if it should be processed
        key_parts = key.split("/")
        path_log_stream_name, path_log_group_name = (
            key_parts[-1],
            key_parts[1].split("_")[-1],
        )
        log_stream_has_prefix = (
            lambda name, prefixes: path_log_group_name == name
            and any(
                path_log_stream_name.startswith(f"{prefix}-i-") for prefix in prefixes
            )
        )
        table = None
        if log_stream_has_prefix("events.log", ("idp", "worker")):
            table = "events"
        elif log_stream_has_prefix("production.log", ("idp",)):
            table = "production"
        return table

    def table_selection(self, key: str, temporary_table: bool = False):
        table = self.map_log_stream_to_table(key)
        if temporary_table:
            # Unextracted tables are used by background job in Rails to extract
            # specific columns from the message super column
            table = f"unextracted_{table}"
        return f"{self.schema_name}.{table}"

    def copy_statement(
        self,
        bucket: str,
        key: str,
        iam_role: str,
        column_list: str,
        temporary_table: bool = True,
    ):
        return super().copy_statement(
            bucket, key, iam_role, column_list, temporary_table
        )

    def merge_statement(self, bucket: str, key: str, iam_role: str, column_list: str):
        target_table = self.table_selection(key)
        id = "uuid" if target_table == "logs.production" else "id"
        return super().merge_statement(bucket, key, iam_role, column_list, [id])


def get_consumption_class(key: str):
    parent_dir = key.split("/")[0]
    if parent_dir == "logs":
        return LogConsumption()
    elif parent_dir == "public":
        return IdpConsumption()
    return None
