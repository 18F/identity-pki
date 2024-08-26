import unittest
import os
from moto import mock_aws
import boto3
from unittest import mock
from db_consumption import lambda_handler
from consumption import get_consumption_class


class IdpConsumptionTest(unittest.TestCase):
    IAM_ROLE = "my:iam:role"
    REDSHIFT_CLUSTER = "my-test-cluster"
    OBJECT_KEY = "public/webauthn_configurations/LOAD00000001.csv"
    INVALID_OBJECT_KEY = "some/folder/structure/LOAD00000001.csv"
    BUCKET_NAME = "my-bucket"
    IDP_TEST_CSV = """Time,Event,User,Location,Status
2023-10-01T12:00:00Z,Login,User1,New York,Success
2023-10-01T12:05:00Z,Logout,User2,San Francisco,Success"""
    CONSUMPTION_CLASS = get_consumption_class(OBJECT_KEY)

    def test_get_consumption_class(self):
        consumption_class = get_consumption_class(self.OBJECT_KEY)
        self.assertEqual(consumption_class.schema_name, "idp")
        assert consumption_class.refresh_table == True

    def test_get_consumption_class_none(self):
        consumption_class = get_consumption_class(self.INVALID_OBJECT_KEY)
        self.assertEqual(consumption_class, None)

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
        self.stub_s3_with_content(self.BUCKET_NAME, self.OBJECT_KEY, self.IDP_TEST_CSV)
        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": self.BUCKET_NAME},
                        "object": {"key": self.OBJECT_KEY},
                    }
                }
            ],
        }

        with self.assertLogs() as log:
            lambda_handler(event=event, context=None, started_means_done=True)

            self.assertIn(
                "TRUNCATE TABLE idp.webauthn_configurations;",
                log.output[0],
                "pulls the table name from the s3 path and creates a TRUNCATE statement",
            )

            self.assertIn(
                'COPY idp.webauthn_configurations ("Time", "Event", "User", "Location", "Status")',
                log.output[4],
                "pulls the table name from the s3 path and creates a COPY statement",
            )

        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": self.BUCKET_NAME},
                        "object": {"key": self.INVALID_OBJECT_KEY},
                    }
                }
            ],
        }

        with self.assertLogs() as log:
            lambda_handler(event=event, context=None, started_means_done=True)

            self.assertIn(
                f"Could not find consumption class for file '{self.INVALID_OBJECT_KEY}'. Skipping.",
                log.output[0],
                "pulls the table name from the s3 path and creates a TRUNCATE statement",
            )

    def test_table_selection(self):
        self.assertEqual(
            self.CONSUMPTION_CLASS.table_selection(self.OBJECT_KEY),
            "idp.webauthn_configurations",
            "pulls the table name from the s3 path",
        )

    def test_temp_table_statement(self):
        sql = self.CONSUMPTION_CLASS.temp_table_statement(self.OBJECT_KEY)

        self.assertIn(
            "CREATE TEMP TABLE idp_webauthn_configurations_temp(LIKE idp.webauthn_configurations);",
            sql,
        )

    def test_truncate_table_statement(self):
        sql = self.CONSUMPTION_CLASS.truncate_target_table_statement(self.OBJECT_KEY)

        self.assertIn("TRUNCATE TABLE idp.webauthn_configurations;", sql)

    @mock_aws
    def test_get_column_headers(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY, self.IDP_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY
        )
        self.assertEqual(column_string, ["Time", "Event", "User", "Location", "Status"])

    @mock_aws
    def test_copy_statement(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY, self.IDP_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY
        )
        sql = self.CONSUMPTION_CLASS.copy_statement(
            self.BUCKET_NAME, self.OBJECT_KEY, self.IAM_ROLE, column_string
        )
        expected_sql = f"""COPY idp.webauthn_configurations ("Time", "Event", "User", "Location", "Status")
        FROM 's3://my-bucket/{self.OBJECT_KEY}'
        IAM_ROLE '{self.IAM_ROLE}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;"""
        self.assertEqual(expected_sql, sql)

    @mock_aws
    def test_merge_statement(self):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY, self.IDP_TEST_CSV
        )
        column_string = self.CONSUMPTION_CLASS.get_column_headers(
            s3, self.BUCKET_NAME, self.OBJECT_KEY
        )
        sql = self.CONSUMPTION_CLASS.merge_statement(
            self.BUCKET_NAME, self.OBJECT_KEY, self.IAM_ROLE, column_string
        )
        expected_sql = f"""BEGIN;
        CREATE TEMP TABLE idp_webauthn_configurations_temp(LIKE idp.webauthn_configurations);
        COPY idp_webauthn_configurations_temp ("Time", "Event", "User", "Location", "Status")
        FROM 's3://{self.BUCKET_NAME}/{self.OBJECT_KEY}'
        IAM_ROLE '{self.IAM_ROLE}'
        CSV
        DELIMITER ','
        IGNOREHEADER 1
        TIMEFORMAT 'auto'
        EXPLICIT_IDS;
        MERGE INTO idp.webauthn_configurations USING idp_webauthn_configurations_temp
        ON idp.webauthn_configurations.id = idp_webauthn_configurations_temp.id REMOVE DUPLICATES;
        COMMIT;"""
        self.assertEqual(expected_sql, sql)
