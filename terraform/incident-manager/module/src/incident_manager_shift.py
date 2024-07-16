import json
import os
import logging
import boto3
from datetime import datetime
from datetime import timedelta
from dateutil.tz import *

logger = logging.getLogger()
logger.setLevel(logging.INFO)
contacts_manager = boto3.client("ssm-contacts")
sns = boto3.client("sns")


def lambda_handler(event, context):
    now = datetime.now(tzlocal())
    day_start = datetime(now.year, now.month, now.day)
    day_end = day_start + timedelta(1)

    rotations = [
        rotation for rotation in contacts_manager.list_rotations()["Rotations"]
    ]

    for rotation in rotations:
        shifts = contacts_manager.list_rotation_shifts(
            RotationId=rotation["RotationArn"],
            StartTime=day_start,
            EndTime=day_end,
        )["RotationShifts"]
        for shift in shifts:
            if len(shift["ContactIds"]) > 0:
                if compare_times(now, shift["StartTime"]):
                    send_to_slack(
                        rotation["Name"], shift["ContactIds"][0].split("/")[1], "ON"
                    )
                elif compare_times(now, shift["EndTime"]):
                    send_to_slack(
                        rotation["Name"], shift["ContactIds"][0].split("/")[1], "OFF"
                    )


def compare_times(a, b):
    return (
        int(
            (
                a.replace(second=0, microsecond=0) - b.replace(second=0, microsecond=0)
            ).total_seconds()
        )
        == 0
    )


def send_to_slack(rotation_name, contact_name, status):
    sns.publish(
        TargetArn=os.environ["SNS_CHANNEL"],
        Message=json.dumps(
            {
                "default": json.dumps(
                    {
                        "IncidentManagerEvent": "ShiftChange",
                        "Details": {
                            "RotationName": rotation_name,
                            "ContactName": contact_name,
                            "Status": status,
                        },
                    }
                )
            }
        ),
        MessageStructure="json",
    )
