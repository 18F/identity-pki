from __future__ import print_function

import json
import os
from datetime import datetime

import boto3


def lambda_handler(event, context):
    count = len(event["Records"])

    current_time = datetime.now().isoformat()
    environment = str(os.environ.get("env"))
    region = event["Records"][0]["awsRegion"]

    runbook = "\n\nRunbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/KMS-Unmatched-Events-Runbook"

    description = "*" + str(count) + "* unmatched events have been detected"

    log_group_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#logsV2:log-groups/log-group/{environment}_unmatched_kms_events"

    sample_size = 10 if count > 10 else count
    samples = ""

    for i in range(sample_size):
        message = json.loads(event["Records"][i]["body"])
        uuid = message["detail"]["uuid"]
        samples += "\t" + str(uuid) + "\n"

    reason = "\n".join(
        [
            "The following UUID samples have been provided for diagnostics.\n",
            samples,
            "Please review the following URL for full list of UUIDs:",
            log_group_url,
        ]
    )

    message = {
        "AlarmName": environment + " Unmatched KMS Events",
        "AlarmDescription": description + runbook,
        "NewStateValue": "ALARM",
        "NewStateReason": reason,
        "StateChangeTime": current_time,
        "Region": region,
    }

    sns = boto3.client("sns")
    sns.publish(
        TargetArn=os.environ.get("arn"),
        Message=json.dumps({"default": json.dumps(message)}),
        MessageStructure="json",
    )
