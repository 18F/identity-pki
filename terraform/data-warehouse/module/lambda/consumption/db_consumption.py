import os
import boto3
from consumption import get_consumption_class
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context, started_means_done=False):
    redshift = boto3.client("redshift-data")
    s3 = boto3.client("s3")
    records = event.get("Records")
    iam_role = os.environ["IAM_ROLE"]
    redshift_cluster = os.environ["REDSHIFT_CLUSTER"]

    try:
        for entry in records:
            s3_data = entry.get("s3", {})
            bucket = s3_data["bucket"]["name"]
            key = s3_data["object"]["key"]
            db_consumption = get_consumption_class(key)
            if db_consumption is None or (
                db_consumption.schema_name == "logs"
                and db_consumption.map_log_stream_to_table(key) is None
            ):
                logger.info(
                    f"Could not find consumption class for file '{key}'. Skipping."
                )
                continue
            if db_consumption.refresh_table:
                truncate_statement = db_consumption.truncate_target_table_statement(key)
                db_consumption.execute_sql_statement(
                    redshift,
                    truncate_statement,
                    redshift_cluster,
                    started_means_done,
                )

            column_list = db_consumption.get_column_headers(s3, bucket, key)

            copy_statement = db_consumption.copy_statement(
                bucket, key, iam_role, column_list
            )
            db_consumption.execute_sql_statement(
                redshift,
                copy_statement,
                redshift_cluster,
                started_means_done,
            )
    except Exception as e:
        logger.error(f"{e}")
        pass
    finally:
        redshift.close()
