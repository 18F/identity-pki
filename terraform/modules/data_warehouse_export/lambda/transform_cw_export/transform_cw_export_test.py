import unittest
import boto3
import botocore
import gzip
import csv
import os
import json
from datetime import datetime
from unittest import mock
from moto import mock_aws
from io import StringIO
from transform_cw_export import (
    convert_to_csv,
    lambda_handler,
    get_unique_id_name,
    uuid5,
)


class TestTransformCWExport(unittest.TestCase):
    @mock_aws
    def test_convert_to_csv_events_log(self):
        s3_client, bucket, key = self.stub_s3_with_content()
        destination_key = "out/file.csv"

        convert_to_csv(
            s3_client=s3_client,
            bucket=bucket,
            key=key,
            destination_key=destination_key,
            json_encoded=False,
        )

        rows = self.read_csv_from_s3(s3_client, bucket, destination_key)

        self.assertEqual(2, len(rows), "keeps all lines when json_encode is False")
        self.assertIn("id", json.loads(rows[1]["message"]), "id field added")

    @mock_aws
    def test_convert_to_csv_production_log(self):
        s3_client, bucket, key = self.stub_s3_with_content(
            key="logs/env__srv_idp_shared_log_production.log/000000.gz"
        )
        destination_key = "out/file.csv"

        convert_to_csv(
            s3_client=s3_client,
            bucket=bucket,
            key=key,
            destination_key=destination_key,
            json_encoded=False,
        )

        rows = self.read_csv_from_s3(s3_client, bucket, destination_key)

        self.assertEqual(2, len(rows), "keeps all lines when json_encode is False")
        self.assertIn("uuid", json.loads(rows[1]["message"]), "uuid field added")

    @mock_aws
    def test_json_encoded_convert_to_csv(self):
        s3_client, bucket, key = self.stub_s3_with_content(
            data="""
2024-01-01T00:00:00.000Z # Logfile example thing
2024-01-01T23:59:59.000Z {"name":"test_event","properties":{"user_id":"abcdef","event_properties":{"sucess":true}}}
2024-01-01T23:59:59.000Z {:name=>""unused_identity_config_keys"", :keys=>[:ab_testing_idv_ten_digit_otp_enabled, :ab_testing_idv_ten_digit_otp_percent, :acuant_timeout, :disallow_all_web_crawlers, :doc_auth_exit_question_section_enabled, :doc_auth_selfie_capture_enabled, :platform_authentication_enabled, :phone_recaptcha_mock_validator]}
""".strip()
        )
        destination_key = "out/file.csv"

        convert_to_csv(
            s3_client=s3_client,
            bucket=bucket,
            key=key,
            destination_key=destination_key,
            json_encoded=True,
        )

        rows = self.read_csv_from_s3(s3_client, bucket, destination_key)

        self.assertEqual(1, len(rows), "only keeps JSON lines whe json_encode is True")

    @mock_aws
    def test_quoting_preserves_json_convert_to_csv(self):
        s3_client, bucket, key = self.stub_s3_with_content(
            data="""
2024-02-01T23:59:59.000Z {"name":"test_event","properties":{"user_agent":"\\\"Xpanse-bot"}}
2024-02-01T23:59:59.000Z {"name":"test_event","properties":{"user_agent":"Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X)"}}
""".strip()
        )
        destination_key = "out/file.csv"

        convert_to_csv(
            s3_client=s3_client,
            bucket=bucket,
            key=key,
            destination_key=destination_key,
            json_encoded=True,
        )

        content = self.read_file_from_s3(s3_client, bucket, destination_key)
        self.assertNotIn(
            '"', content.splitlines(), "does not contain double quotes on its own line"
        )

        rows = self.read_csv_from_s3(s3_client, bucket, destination_key)
        for user_agent, row in zip(
            ['"Xpanse-bot', "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X)"],
            rows,
        ):
            try:
                self.assertEqual(
                    user_agent, json.loads(row["message"])["properties"]["user_agent"]
                )
            except json.decoder.JSONDecodeError:
                self.assertTrue(
                    False, f"could not JSON decode string:\n\n{row['message']}"
                )

    def test_get_unique_id_name(self):
        self.assertEqual(
            "id",
            get_unique_id_name("logs/env__srv_idp_shared_log_events.log/000000.gz"),
        )
        self.assertEqual(
            "uuid",
            get_unique_id_name("logs/env__srv_idp_shared_log_production.log/000000.gz"),
        )

    def test_uuid5(self):
        self.assertEqual(
            "651adf85-f0d5-5e44-b606-978e039dd9b9",
            str(uuid5('{"test1":"value1"}"')),
            "generates a UUIDv5 from a string",
        )
        self.assertEqual(
            "b73a32a9-6dfe-5602-843e-9a8b1c4ceedb",
            str(uuid5('{"test2":"value2"}"')),
            "generates a UUIDv5 from a string",
        )

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "LOG_GROUPS": json.dumps(
                [
                    {
                        "name": "testenv_/srv/idp/shared/log/events.log",
                        "json_encoded": True,
                    }
                ]
            ),
        },
        clear=True,
    )
    @mock_aws
    def test_lambda_handler(self):
        bucket = "login-gov-analytics-export-testenv-00000-us-west-2"
        in_key = "logs/testenv__srv_idp_shared_log_events.log/2c9dfc79-67eb-4c69-98df-3e290be10633/idp-i-0010b111c6ac79429.testenv.identitysandbox.gov/000000.gz"
        out_key = datetime.now().strftime(
            "logs/testenv__srv_idp_shared_log_events.log/processed/%Y/%m/%d/idp-i-0010b111c6ac79429.testenv.identitysandbox.gov.000000.csv"
        )
        s3_client, _, _ = self.stub_s3_with_content(bucket=bucket, key=in_key)
        self.stub_logs(
            log_group_name="testenv_/srv/idp/shared/log/events.log",
            log_stream_name="idp-i-0010b111c6ac79429.testenv.identitysandbox.gov",
        )

        event = self.build_event(bucket=bucket, key=in_key)
        lambda_handler(event, context=None)

        rows = self.read_csv_from_s3(s3_client, bucket, key=out_key)
        self.assertEqual(len(rows), 1, "only keeps JSON rows")
        (row,) = rows
        self.assertEqual(row.get("cloudwatch_timestamp"), "2024-01-01T23:59:59.000Z")
        self.assertEqual(
            row.get("message"),
            '{"name":"test_event","properties":{"user_id":"abcdef","event_properties":{"sucess":true}},"id":"05b0c167-da0f-556e-92a7-c444565161bc"}',
        )

        self.assertFalse(
            self.bucket_has_key(s3_client=s3_client, bucket=bucket, key=in_key),
            "it deletes the original file",
        )

    def stub_s3_with_content(
        self,
        bucket="logsbucket",
        key="logs/env__srv_idp_shared_log_events.log/000000.gz",
        data=None,
    ):
        data = (
            data
            or """
2024-01-01T00:00:00.000Z # Logfile example thing
2024-01-01T23:59:59.000Z {"name":"test_event","properties":{"user_id":"abcdef","event_properties":{"sucess":true}}}
""".strip()
        )

        gzipped = gzip.compress(data.encode("utf-8"))

        s3_client = boto3.client("s3")

        s3_client.create_bucket(
            Bucket=bucket,
            CreateBucketConfiguration={
                "LocationConstraint": os.environ.get("AWS_DEFAULT_REGION", "us-east-2"),
            },
        )
        s3_client.put_object(
            Bucket=bucket,
            Key=key,
            Body=gzipped,
        )

        return (s3_client, bucket, key)

    def stub_logs(self, log_group_name, log_stream_name):
        logs_client = boto3.client("logs")

        logs_client.create_log_group(logGroupName=log_group_name)
        logs_client.create_log_stream(
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
        )

    def build_event(self, bucket, key):
        return {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": bucket},
                        "object": {"key": key},
                    }
                }
            ]
        }

    def read_file_from_s3(self, s3_client, bucket, key):
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return response["Body"].read().decode("utf-8")

    def read_csv_from_s3(self, s3_client, bucket, key):
        content = StringIO(self.read_file_from_s3(s3_client, bucket, key))

        reader = csv.DictReader(content, delimiter=",")
        return list(reader)

    def bucket_has_key(self, s3_client, bucket, key):
        try:
            s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except botocore.exceptions.ClientError:
            return False


if __name__ == "__main__":
    unittest.main()
