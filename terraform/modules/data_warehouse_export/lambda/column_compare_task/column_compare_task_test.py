import json
import boto3
import os
import unittest
from moto import mock_aws
from unittest.mock import patch
from column_compare_task import lambda_handler


@mock_aws
class TestColumnCompare(unittest.TestCase):
    dms_task_arn = "arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKL"
    bucket = "login-gov-analytics-export-testenv-00000-us-west-2"
    s3_folder_name = (
        "daily-sensitive-column-job/2024/2024-10-15_daily-sensitive-column-job.json"
    )
    normal_data = """{"sensitive":[],"insensitive":[{"object-locator":{"column-name":"user_id","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"name","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"totp_timestamp","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"created_at","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"updated_at","table-name":"auth_app_configurations"}}]}"""
    sensitive_data = """{"sensitive":[{"object-locator":{"column-name":"encrypted_otp_secret_key","table-name":"auth_app_configurations"}}],"insensitive":[{"object-locator":{"column-name":"user_id","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"name","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"totp_timestamp","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"created_at","table-name":"auth_app_configurations"}},{"object-locator":{"column-name":"updated_at","table-name":"auth_app_configurations"}}]}"""

    @patch.dict(
        os.environ,
        {
            "DMS_TASK_ARN": dms_task_arn,
            "AWS_DEFAULT_REGION": "us-east-1",
            "S3_BUCKET": bucket,
        },
        clear=True,
    )
    @patch("logging.getLogger")
    def test_normal_lambda_handler(self, mock_logger):
        self.stub_bucket(self.bucket, self.s3_folder_name, self.normal_data)
        self.stub_dms()

        lambda_handler(event=None, context=None)

        mock_logger().info.assert_any_call(
            "No Sensitive columns in the DMS import rules"
        )

    @patch.dict(
        os.environ,
        {
            "DMS_TASK_ARN": dms_task_arn,
            "AWS_DEFAULT_REGION": "us-east-1",
            "S3_BUCKET": bucket,
        },
        clear=True,
    )
    @patch("logging.getLogger")
    def test_bad_lambda_handler(self, mock_logger):
        self.stub_bucket(self.bucket, self.s3_folder_name, self.normal_data)
        try:
            lambda_handler(event=None, context=None)
        except Exception as e:
            self.assertEqual(str(e), "No DMS mapping rules found in specified DMS ARN")

    @patch.dict(
        os.environ,
        {
            "DMS_TASK_ARN": dms_task_arn,
            "AWS_DEFAULT_REGION": "us-east-1",
            "S3_BUCKET": bucket,
        },
        clear=True,
    )
    @patch("logging.getLogger")
    def test_sensitive_lambda_handler(self, mock_logger):

        self.stub_bucket(self.bucket, self.s3_folder_name, self.sensitive_data)
        self.stub_dms()
        lambda_handler(event=None, context=None)
        mock_logger().error.assert_any_call(
            "DMS Column Discrepancy: Some columns are missing in DMS import rules"
        )
        mock_logger().error.assert_any_call(
            "DMS Column Discrepancy: Some columns no longer exist in IDP"
        )
        mock_logger().error.assert_any_call(
            "Sensitive columns are in the DMS import rules"
        )

    def stub_bucket(self, bucket_name, folder_name, data):
        s3_client = boto3.client("s3")
        s3_client.create_bucket(
            Bucket=bucket_name,
        )
        s3_client.put_object(Bucket=bucket_name, Key=folder_name, Body=data)

    def stub_dms(self):
        json_data = {
            "rules": [
                {
                    "object-locator": {
                        "column-name": "encrypted_otp_secret_key",
                        "schema-name": "public",
                        "table-name": "auth_app_configurations",
                    },
                    "old-value": None,
                    "rule-action": "include-column",
                    "rule-id": "200000000",
                    "rule-name": "transformation-rule-auth_app_configurations-include-column-encrypted_otp_secret_key",
                    "rule-target": "column",
                    "rule-type": "transformation",
                    "value": None,
                },
                {
                    "object-locator": {
                        "column-name": "user_id",
                        "schema-name": "public",
                        "table-name": "auth_app_configurations",
                    },
                    "old-value": None,
                    "rule-action": "include-column",
                    "rule-id": "200000001",
                    "rule-name": "transformation-rule-auth_app_configurations-include-column-user_id",
                    "rule-target": "column",
                    "rule-type": "transformation",
                    "value": None,
                },
                {
                    "object-locator": {
                        "column-name": "id",
                        "schema-name": "public",
                        "table-name": "auth_app_configurations",
                    },
                    "old-value": None,
                    "rule-action": "include-column",
                    "rule-id": "200000002",
                    "rule-name": "transformation-rule-auth_app_configurations-include-column-id",
                    "rule-target": "column",
                    "rule-type": "transformation",
                    "value": None,
                },
                {
                    "object-locator": {
                        "column-name": "service_provider",
                        "schema-name": "public",
                        "table-name": "identities",
                    },
                    "old-value": None,
                    "rule-action": "include-column",
                    "rule-id": "200000002",
                    "rule-name": "transformation-rule-identities-include-column-service_provider",
                    "rule-target": "column",
                    "rule-type": "transformation",
                    "value": None,
                },
            ]
        }
        dms_client = boto3.client("dms")

        dms_client.create_replication_task(
            ReplicationInstanceArn="arn",
            ReplicationTaskIdentifier="task-1",
            SourceEndpointArn="arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKL",
            TargetEndpointArn="arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKL",
            MigrationType="full-load",
            TableMappings=json.dumps(json_data),
        )
