import unittest
import os
import boto3
from moto import mock_aws
from unittest import mock
from db_consumption import lambda_handler
from consumption import get_consumption_class


class LogConsumptionTest(unittest.TestCase):
    IAM_ROLE = "my:iam:role"
    REDSHIFT_CLUSTER = "my-test-cluster"
    OBJECT_KEY_EVENTS = "logs/env_log_events.log/processed/2024/05/17/idp-i-events.csv"
    OBJECT_KEY_PRODUCTION = (
        "logs/env_log_production.log/processed/2024/05/17/idp-i-production.csv"
    )
    BUCKET_NAME = "my-bucket"
    LOGS_TEST_CSV = """cloudwatch_timestamp,message
    2024-05-17 12:00:00,This is the first test message
    2024-05-17 12:01:00,This is the second test message"""
    CONSUMPTION_CLASS = get_consumption_class(OBJECT_KEY_EVENTS)

    def test_get_consumption_class(self):
        consumption_class = get_consumption_class(self.OBJECT_KEY_EVENTS)
        self.assertEqual(consumption_class.schema_name, "logs")
        assert consumption_class.refresh_table == False

    def stub_s3_with_content(self, bucket, key, body):
        s3 = boto3.client("s3")
        s3.create_bucket(
            Bucket=bucket,
            CreateBucketConfiguration={
                "LocationConstraint": os.environ.get("AWS_DEFAULT_REGION", "us-west-2"),
            },
        )

        s3.put_object(Bucket=bucket, Key=key, Body=body)

        return s3

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "IAM_ROLE": IAM_ROLE,
            "REDSHIFT_CLUSTER": REDSHIFT_CLUSTER,
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock.patch("time.sleep", return_value=None)
    @mock_aws
    def test_lambda_handler(self, patched_time_sleep, patched_print):
        self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.LOGS_TEST_CSV
        )
        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": self.BUCKET_NAME},
                        "object": {"key": self.OBJECT_KEY_EVENTS},
                    }
                }
            ],
        }
        with self.assertLogs() as log:
            lambda_handler(event=event, context=None, started_means_done=True)

            self.assertIn(
                "COPY logs.unextracted_events",
                log.output[1],
                "pulls the table name from the s3 path and creates a COPY statement",
            )

    def test_table_selection(self):
        self.assertEqual(
            self.CONSUMPTION_CLASS.table_selection(self.OBJECT_KEY_EVENTS),
            "logs.events",
            "pulls the table name from the s3 path",
        )
        worker_key = "logs/env_log_events.log/processed/2024/05/17/worker-i-events.csv"
        self.assertEqual(
            self.CONSUMPTION_CLASS.table_selection(worker_key),
            "logs.events",
            "pulls the table name from the s3 path",
        )

    def test_temp_table_statement(self):
        sql = self.CONSUMPTION_CLASS.temp_table_statement(self.OBJECT_KEY_EVENTS)

        self.assertIn(
            "CREATE TEMP TABLE logs.unextracted_events(LIKE logs.events);",
            sql,
        )

    @mock_aws
    def test_get_column_headers(self):

        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.LOGS_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY_EVENTS
        )
        self.assertEqual(column_string, ["cloudwatch_timestamp", "message"])

    @mock_aws
    def test_copy_statement(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.LOGS_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY_EVENTS
        )
        sql = self.CONSUMPTION_CLASS.copy_statement(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.IAM_ROLE, column_string
        )
        expected_sql = f"""COPY logs.unextracted_events ("cloudwatch_timestamp", "message")
        FROM 's3://my-bucket/{self.OBJECT_KEY_EVENTS}'
        IAM_ROLE '{self.IAM_ROLE}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;"""
        self.assertEqual(expected_sql, sql)

    @mock_aws
    def test_merge_statement_events_table(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.LOGS_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY_EVENTS
        )
        sql = self.CONSUMPTION_CLASS.merge_statement(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.IAM_ROLE, column_string
        )
        expected_sql = f"""BEGIN;
        CREATE TEMP TABLE logs.unextracted_events(LIKE logs.events);
        COPY logs.unextracted_events ("cloudwatch_timestamp", "message")
        FROM 's3://{self.BUCKET_NAME}/{self.OBJECT_KEY_EVENTS}'
        IAM_ROLE '{self.IAM_ROLE}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;
        MERGE INTO logs.events USING logs.unextracted_events
        ON logs.events.id = logs.unextracted_events.id REMOVE DUPLICATES;
        COMMIT;"""
        self.assertEqual(expected_sql, sql)

    @mock_aws
    def test_merge_statement_production_table(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY_EVENTS, self.LOGS_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY_EVENTS
        )
        sql = self.CONSUMPTION_CLASS.merge_statement(
            self.BUCKET_NAME, self.OBJECT_KEY_PRODUCTION, self.IAM_ROLE, column_string
        )
        expected_sql = f"""BEGIN;
        CREATE TEMP TABLE logs.unextracted_production(LIKE logs.production);
        COPY logs.unextracted_production ("cloudwatch_timestamp", "message")
        FROM 's3://{self.BUCKET_NAME}/{self.OBJECT_KEY_PRODUCTION}'
        IAM_ROLE '{self.IAM_ROLE}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;
        MERGE INTO logs.production USING logs.unextracted_production
        ON logs.production.uuid = logs.unextracted_production.uuid REMOVE DUPLICATES;
        COMMIT;"""
        self.assertEqual(expected_sql, sql)
