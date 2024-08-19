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
    previous_day_begin = current_time.replace(
        hour=0, minute=0, second=0, microsecond=0
    ) - timedelta(days=1)
    previous_day_end = current_time.replace(hour=0, minute=0, second=0, microsecond=0)
    start_time_ms, end_time_ms = (
        previous_day_begin.timestamp() * 1000,
        previous_day_end.timestamp() * 1000,
    )

    error_msgs = []
    for log_group in log_groups:
        log_group_name = log_group["name"]
        prefix = "logs/" + log_group_name.replace("/", "_")
        try:
            create_response = logs.create_export_task(
                logGroupName=log_group_name,
                fromTime=int(start_time_ms),
                to=int(end_time_ms),
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
                elif status in ("CANCELLED", "FAILED"):
                    raise Exception(
                        f"Export Task failed for {log_group_name}, status={status} task_id={task_id}"
                    )
                elif status in ("PENDING", "PENDING_CANCEL", "RUNNING"):
                    pass
                else:
                    raise Exception(
                        f"Unknown status, status={status} task_id={task_id}"
                    )
        except Exception as e:
            error_msgs.append(
                "Error exporting %s: %s"
                % (log_group_name, getattr(e, "message", repr(e)))
            )
        if error_msgs:
            raise Exception("\n".join(error_msgs))
