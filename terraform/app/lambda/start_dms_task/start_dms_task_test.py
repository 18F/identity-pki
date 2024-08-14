import boto3
import logging
import os
import time
import unittest
from moto import mock_aws
from unittest.mock import patch, MagicMock
from start_dms_task import lambda_handler


@mock_aws
class TestStartDMSTask(unittest.TestCase):
    dms_task_arn = "arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKL"

    @patch.dict(
        os.environ,
        {"DMS_TASK_ARN": dms_task_arn},
        clear=True,
    )
    @patch("boto3.client")
    @patch("logging.getLogger")
    def test_lambda_handler(self, mock_logger, mock_boto3_client):
        # Setup
        self.stub_dms(mock_boto3_client)

        # Execute
        lambda_handler(event={}, context={})

        # Verify
        mock_logger.assert_called_once()
        mock_logger().setLevel.assert_called_once_with(logging.INFO)
        mock_logger().info.assert_called_once_with(
            f"Task {self.dms_task_arn} started successfully. Status: running"
        )

    def stub_dms(self, mock_boto3_client):
        mock_dms = MagicMock()
        mock_boto3_client.return_value = mock_dms

        mock_dms.describe_replication_tasks.return_value = {
            "ReplicationTasks": [{"Status": "ready"}]
        }

        mock_dms.start_replication_task.return_value = {
            "ReplicationTask": {
                "ReplicationTaskIdentifier": self.dms_task_arn,
                "Status": "running",
            }
        }
