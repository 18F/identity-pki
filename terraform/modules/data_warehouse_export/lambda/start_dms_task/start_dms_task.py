import logging
import os

import boto3


def lambda_handler(event, context):
    dms = boto3.client("dms")
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if "DMS_TASK_ARN" not in os.environ:
        raise Exception("DMS_TASK_ARN not defined")

    current_dms_status = dms.describe_replication_tasks(
        Filters=[
            {
                "Name": "replication-task-arn",
                "Values": [
                    os.environ["DMS_TASK_ARN"],
                ],
            },
        ]
    )["ReplicationTasks"][0]["Status"]

    task_type = (
        "start-replication"
        if current_dms_status in ["failed", "ready"]
        else "reload-target"
    )

    response = dms.start_replication_task(
        ReplicationTaskArn=os.environ["DMS_TASK_ARN"],
        StartReplicationTaskType=task_type,
    )

    identifier = response["ReplicationTask"]["ReplicationTaskIdentifier"]
    status = response["ReplicationTask"]["Status"]

    if status == "running" or status == "starting":
        logger.info(f"Task {identifier} started successfully. Status: {status}")
    elif status == "failed":
        raise Exception(f"Task {identifier} failed to start. Status: {status}")
