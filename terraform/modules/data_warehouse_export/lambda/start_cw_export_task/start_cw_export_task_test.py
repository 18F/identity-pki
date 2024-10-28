import boto3
import json
import os
import unittest
import time
import math
from moto import mock_aws
from unittest import mock
from start_cw_export_task import lambda_handler


class TestStartCWExportTask(unittest.TestCase):
    BUCKET_NAME = "my-bucket"
    LOG_GROUP_NAME = "testenv_/srv/idp/shared/log/events.log"

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "S3_BUCKET": BUCKET_NAME,
            "LOG_GROUPS": json.dumps(
                [
                    {
                        "name": LOG_GROUP_NAME,
                    }
                ]
            ),
        },
        clear=True,
    )
    @mock.patch("time.sleep", return_value=None)
    @mock_aws
    def test_lambda_handler(self, patched_time_sleep):
        self.stub_bucket(self.BUCKET_NAME)
        self.stub_logs(self.LOG_GROUP_NAME, "some_log_stream_name")

        lambda_handler(event=None, context=None)

        self.assertTrue(patched_time_sleep.called)

        logs = boto3.client("logs")
        response = logs.describe_export_tasks()
        (task,) = response["exportTasks"]
        self.assertEqual(task["logGroupName"], self.LOG_GROUP_NAME)

    def stub_bucket(self, bucket_name):
        s3_client = boto3.client("s3")
        s3_client.create_bucket(
            Bucket=bucket_name,
            CreateBucketConfiguration={
                "LocationConstraint": os.environ.get("AWS_DEFAULT_REGION", "us-east-2"),
            },
        )

    def stub_logs(self, log_group_name, log_stream_name):
        logs_client = boto3.client("logs")

        logs_client.create_log_group(logGroupName=log_group_name)
        logs_client.create_log_stream(
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
        )
