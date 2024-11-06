import os
import boto3
import json
from datetime import datetime
import logging
import time

# Initialize AWS clients outside the handler for better performance
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def wait_for_completion(redshift_client, statement_id, started_means_done):
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


def get_redshift_tables_list(redshift_data_client, started_means_done):
    response = redshift_data_client.execute_statement(
        ClusterIdentifier=os.environ["REDSHIFT_CLUSTER"],
        Database="analytics",
        Sql="""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'idp';
        """,
    )
    query_id = response["Id"]
    wait_for_completion(redshift_data_client, query_id, started_means_done)

    result = redshift_data_client.get_statement_result(Id=query_id)
    tables = [row[0].get("stringValue") for row in result["Records"]]

    if not tables:
        print_log_message = {
            "name": "StaleDataCheck",
            "success": False,
            "message": "No tables were returned from the query. Please investigate.",
        }
        logger.info(print_log_message)
        raise Exception("No tables were returned from the query.")

    logger.info(f"Tables: {tables} successfully retrieved")
    return tables


def get_redshift_table_stats(redshift_data_client, table, started_means_done):
    response = redshift_data_client.execute_statement(
        ClusterIdentifier=os.environ["REDSHIFT_CLUSTER"],
        Database="analytics",
        Sql=f"""
            SELECT COUNT(*) AS row_count, MAX(id) AS max_id
            FROM idp.{table};
        """,
    )

    query_id = response["Id"]
    wait_for_completion(redshift_data_client, query_id, started_means_done)

    result = redshift_data_client.get_statement_result(Id=query_id)
    rows = result["Records"]
    if rows:
        row_count = rows[0][0].get("longValue", 0)
        max_id = rows[0][1].get("longValue", 0)
        return {"row_count": row_count, "max_id": max_id}

    return None


def get_all_redshift_table_stats(redshift_data_client, started_means_done):
    tables = get_redshift_tables_list(redshift_data_client, started_means_done)
    table_stats = {}
    for table in tables:
        stats = get_redshift_table_stats(
            redshift_data_client, table, started_means_done
        )
        if stats:
            table_stats[table] = {
                "row_count": stats["row_count"],
                "max_id": stats["max_id"],
            }
    logger.info(f"Table stats successfully retrieved: {table_stats}")
    return table_stats


def get_idp_stats_from_s3(s3_client, s3_bucket, s3_key):
    obj = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
    data = obj["Body"].read().decode("utf-8")
    idp_stats_from_s3 = json.loads(data)
    return idp_stats_from_s3


def calculate_delta(redshift_stats, idp_stats):

    # Only consider tables that exist in both redshift_stats and idp_stats
    common_tables = sorted(
        set(redshift_stats.keys()).intersection(set(idp_stats.keys()))
    )

    for table in common_tables:

        redshift_table_stats = redshift_stats[table]
        idp_table_stats = idp_stats[table]
        max_id_delta = redshift_table_stats["max_id"] - idp_table_stats["max_id"]
        count_delta = redshift_table_stats["row_count"] - idp_table_stats["row_count"]

        # Only fail on max id delta, not count delta, until we have a better understanding of the data
        if max_id_delta != 0:  # or count_delta != 0:
            print_log_message = {
                "name": "StaleDataCheck",
                "success": False,
                "max_id_delta": max_id_delta,
                "count_delta": count_delta,
                "table": table,
            }
        else:
            print_log_message = {
                "name": "StaleDataCheck",
                "success": True,
                "max_id_delta": count_delta,
                "count_delta": count_delta,
                "table": table,
            }

        logger.info(print_log_message)

    return


def lambda_handler(event, context, started_means_done=False):
    redshift_client = boto3.client("redshift-data")
    s3_client = boto3.client("s3")

    records = event.get("Records")
    entry = records.pop()
    s3_data = entry.get("s3", {})
    bucket = s3_data["bucket"]["name"]
    key = s3_data["object"]["key"]

    try:
        path_part, year_part, file_part = key.split("/")
        date_part, idp_part = file_part.split("_", 1)
        datetime.strptime(date_part, "%Y-%m-%d")
        if idp_part != "table_summary_stats.json":
            raise ValueError
        logger.info(f"{path_part}/{year_part}/{file_part}, is a valid file format")

        redshift_stats = get_all_redshift_table_stats(
            redshift_client, started_means_done
        )
        idp_stats = get_idp_stats_from_s3(s3_client, bucket, key)
        calculate_delta(redshift_stats, idp_stats)
    except ValueError:
        logger.error(
            f"Invalid file format: {key}. Expected format: YYYY-MM-DD_table_summary_stats.json"
        )
        return
