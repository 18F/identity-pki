import logging
import os
from datetime import datetime, timezone

import boto3
import json


def lambda_handler(event, context):
    dms = boto3.client("dms")
    s3 = boto3.client("s3")
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if "DMS_TASK_ARN" not in os.environ:
        raise Exception("DMS_TASK_ARN not defined")
    if "S3_BUCKET" not in os.environ:
        raise Exception("S3_BUCKET not defined")

    s3_bucket_name = os.environ["S3_BUCKET"]
    s3_folder_name = f"daily-sensitive-column-job/{datetime.now(timezone.utc).year}/"

    response = dms.describe_replication_tasks(
        Filters=[
            {
                "Name": "replication-task-arn",
                "Values": [os.environ["DMS_TASK_ARN"]],
            },
        ]
    )

    if response["ReplicationTasks"]:
        logger.info(
            f"Replication task settings: {response['ReplicationTasks'][0]['Status']}"
        )

        json.loads(response["ReplicationTasks"][0]["TableMappings"])

        mapping_rules = json.loads(response["ReplicationTasks"][0]["TableMappings"])[
            "rules"
        ]
        filtered_mapping_rules = [
            rule
            for rule in mapping_rules
            if "column-name" in rule["object-locator"]
            and rule["object-locator"].get("column-name") != "id"
        ]

        mapping_set = {
            (
                rule["object-locator"]["table-name"],
                rule["object-locator"]["column-name"],
            )
            for rule in filtered_mapping_rules
        }

        s3_objects = s3.list_objects_v2(Bucket=s3_bucket_name, Prefix=s3_folder_name)

        latest_file = max(s3_objects["Contents"], key=lambda x: x["LastModified"])
        latest_file_key = latest_file["Key"]
        logger.info(f"Latest file in S3 bucket: {latest_file_key}")

        data = s3.get_object(Bucket=s3_bucket_name, Key=latest_file_key)
        contents = data["Body"].read().decode("utf-8")

        json_data = json.loads(contents)

        s3_content_sensitive = json_data.get("sensitive", {})
        s3_content_non_sensitive = json_data.get("insensitive", {})
        s3_sensitive_set = {
            (
                rule["object-locator"]["table-name"],
                rule["object-locator"]["column-name"],
            )
            for rule in s3_content_sensitive
        }

        s3_non_sensitive_set = {
            (
                rule["object-locator"]["table-name"],
                rule["object-locator"]["column-name"],
            )
            for rule in s3_content_non_sensitive
        }

        if not s3_sensitive_set.isdisjoint(mapping_set):
            logger.error("Sensitive columns are in the DMS import rules")
            logger.info(
                f"Sensitive columns in the DMS import rules: {s3_sensitive_set.intersection(mapping_set)}"
            )
        else:
            logger.info("No Sensitive columns in the DMS import rules")

        unmapped_columns = s3_non_sensitive_set - mapping_set
        columns_to_unmap = mapping_set - s3_non_sensitive_set
        if unmapped_columns:
            logger.error(
                "DMS Column Discrepancy: Some columns are missing in DMS import rules"
            )
            logger.info(f"Columns to add to DMS import rules: {unmapped_columns}")
        else:
            logger.info("No missing columns from the mapping rules")
        if columns_to_unmap:
            logger.error("DMS Column Discrepancy: Some columns no longer exist in IDP")
            logger.info(f"Columns to remove from DMS import rules: {columns_to_unmap}")
        else:
            logger.info("No columns to remove from the filteredColumns yaml file")
    else:
        raise Exception("No DMS mapping rules found in specified DMS ARN")
