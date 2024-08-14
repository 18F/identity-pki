import gzip
import io
import json
import logging
import os
import time
from datetime import datetime, timedelta

import boto3


def lambda_handler(event, context):
    logs = boto3.client("logs")
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if "S3_BUCKET" not in os.environ:
        raise Exception("S3_BUCKET not defined")

    bucket = os.environ["S3_BUCKET"]

    if "LOG_GROUPS" not in os.environ:
        raise Exception("LOG_GROUPS not defined")

    if "PREVIOUS_DAYS" not in os.environ:
        previous_days = 1
    else:
        previous_days = int(os.environ["PREVIOUS_DAYS"])

    log_groups = json.loads(os.environ["LOG_GROUPS"])

    logger.debug("S3_BUCKET=%s" % os.environ["S3_BUCKET"])

    current_time = datetime.now()
    now_milliseconds = (current_time + timedelta(minutes=3)).timestamp() * 1000
    from_milliseconds = (
        current_time - timedelta(days=previous_days)
    ).timestamp() * 1000

    for log_group in log_groups:
        log_group_name = log_group["name"]
        prefix = "logs/" + log_group_name.replace("/", "_")
        try:
            create_response = logs.create_export_task(
                logGroupName=log_group_name,
                fromTime=int(from_milliseconds),
                to=int(now_milliseconds),
                destination=bucket,
                destinationPrefix=prefix,
            )

            task_id = create_response["taskId"]
            logger.info(f"Task created for {log_group_name}: {task_id}")

            while True:
                time.sleep(5)
                describe_response = logs.describe_export_tasks(taskId=task_id)

                status = describe_response["exportTasks"][0]["status"]["code"]

                if status == "COMPLETED":
                    logger.info(f"Export Task completed for {log_group_name}")
                    break
                elif status == "CANCELLED" or status == "FAILED":
                    logger.error(f"Export Task failed for {log_group_name}")
                    break
                elif (
                    status == "PENDING"
                    or status == "PENDING_CANCEL"
                    or status == "RUNNING"
                ):
                    pass
                else:
                    raise Exception(f"Unknown status status={status} task_id={task_id}")

        except logs.exceptions.LimitExceededException:
            logger.error(
                "Need to wait until all tasks are finished (LimitExceededException). Continuing later..."
            )

            return

        except Exception as e:
            raise Exception(
                "Error exporting %s: %s"
                % (log_group_name, getattr(e, "message", repr(e)))
            )

            continue
