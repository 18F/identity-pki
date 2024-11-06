import unittest
import os
from moto import mock_aws
import boto3
from unittest import mock
from stale_data_check import (
    wait_for_completion,
    get_redshift_tables_list,
    get_redshift_table_stats,
    get_all_redshift_table_stats,
    get_idp_stats_from_s3,
    calculate_delta,
    lambda_handler,
)

IAM_ROLE = "my:iam:role"
REDSHIFT_CLUSTER = "my-test-cluster"


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
class StaleDataCheckTest(unittest.TestCase):

    OBJECT_KEY = "table_summary_stats/2024/2024-10-01_table_summary_stats.json"
    INVALID_OBJECT_KEY = "some/folder/2024-10-01_something_else.json"
    BUCKET_NAME = "my-bucket"
    MAX_ID_TEST_JSON = """{
        "table1": {"max_id": 100, "row_count": 10},
        "table2": {"max_id": 200, "row_count": 190},
        "table3": {"max_id": 300, "row_count": 300}
    }"""

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

    def test_get_idp_stats_from_s3(self, patched_time_sleep, patched_print):
        s3 = self.stub_s3_with_content(
            self.BUCKET_NAME, self.OBJECT_KEY, self.MAX_ID_TEST_JSON
        )

        max_id_data = get_idp_stats_from_s3(s3, self.BUCKET_NAME, self.OBJECT_KEY)
        expected_data = {
            "table1": {"max_id": 100, "row_count": 10},
            "table2": {"max_id": 200, "row_count": 190},
            "table3": {"max_id": 300, "row_count": 300},
        }
        self.assertEqual(max_id_data, expected_data)

    def test_wait_for_completion_finished(self, patched_time_sleep, patched_print):
        redshift_data = boto3.client("redshift-data")
        redshift_data.describe_statement = mock.Mock(
            return_value={"Status": "FINISHED"}
        )

        result = wait_for_completion(
            redshift_data, "test-query-id", started_means_done=False
        )
        self.assertEqual(result["Status"], "FINISHED")
        self.assertEqual(redshift_data.describe_statement.call_count, 1)

    def test_wait_for_completion_aborted(self, patched_time_sleep, patched_print):
        redshift_data = boto3.client("redshift-data")
        redshift_data.describe_statement = mock.Mock(return_value={"Status": "ABORTED"})

        result = wait_for_completion(
            redshift_data, "test-query-id", started_means_done=False
        )
        self.assertEqual(result["Status"], "ABORTED")
        self.assertEqual(redshift_data.describe_statement.call_count, 1)

    def test_wait_for_completion_started_means_done(
        self, patched_time_sleep, patched_print
    ):
        redshift_data = boto3.client("redshift-data")
        redshift_data.describe_statement = mock.Mock(return_value={"Status": "STARTED"})

        result = wait_for_completion(
            redshift_data, "test-query-id", started_means_done=True
        )
        self.assertEqual(result["Status"], "STARTED")
        self.assertEqual(redshift_data.describe_statement.call_count, 1)

    def test_wait_for_completion_failed(self, patched_time_sleep, patched_print):
        redshift_data = boto3.client("redshift-data")
        redshift_data.describe_statement = mock.Mock(
            return_value={"Status": "FAILED", "Error": "Test error"}
        )

        with self.assertRaises(Exception) as context:
            wait_for_completion(
                redshift_data, "test-query-id", started_means_done=False
            )
        self.assertEqual(str(context.exception), "Test error")
        self.assertEqual(redshift_data.describe_statement.call_count, 1)

    def test_wait_for_completion_multiple_calls(
        self, patched_time_sleep, patched_print
    ):
        redshift_data = boto3.client("redshift-data")
        redshift_data.describe_statement = mock.Mock(
            side_effect=[
                {"Status": "STARTED"},
                {"Status": "SUBMITTED"},
                {"Status": "PICKED"},
                {"Status": "FINISHED"},
            ]
        )

        result = wait_for_completion(
            redshift_data, "test-query-id", started_means_done=False
        )
        self.assertEqual(result["Status"], "FINISHED")
        self.assertEqual(redshift_data.describe_statement.call_count, 4)

    def test_get_redshift_tables_list(self, patched_time_sleep, patched_print):
        redshift_data = boto3.client("redshift-data")
        redshift_data.execute_statement = mock.Mock(
            return_value={"Id": "test-query-id"}
        )
        redshift_data.describe_statement = mock.Mock(
            return_value={"Status": "FINISHED"}
        )
        redshift_data.get_statement_result = mock.Mock(
            return_value={
                "Records": [[{"stringValue": "table1"}], [{"stringValue": "table2"}]]
            }
        )

        os.environ["REDSHIFT_CLUSTER_ID"] = "test-cluster"

        tables = get_redshift_tables_list(redshift_data, started_means_done=True)
        self.assertEqual(tables, ["table1", "table2"])

    def test_get_redshift_table_stats(self, patched_time_sleep, patched_print):
        redshift_data = boto3.client("redshift-data")
        redshift_data.execute_statement = mock.Mock(
            return_value={"Id": "test-query-id"}
        )
        redshift_data.describe_statement = mock.Mock(
            return_value={"Status": "FINISHED"}
        )
        redshift_data.get_statement_result = mock.Mock(
            return_value={"Records": [[{"longValue": 10}, {"longValue": 100}]]}
        )

        os.environ["REDSHIFT_CLUSTER_ID"] = "test-cluster"

        stats = get_redshift_table_stats(
            redshift_data, "table1", started_means_done=True
        )
        expected_stats = {"row_count": 10, "max_id": 100}
        self.assertEqual(stats, expected_stats)

    @mock.patch(
        "stale_data_check.get_redshift_tables_list",
        return_value=["table1", "table2"],
    )
    def test_get_all_redshift_table_stats(
        self, mock_get_tables, patched_time_sleep, patched_print
    ):
        redshift_data = boto3.client("redshift-data")
        redshift_data.execute_statement = mock.Mock(
            return_value={"Id": "test-query-id"}
        )
        redshift_data.describe_statement = mock.Mock(
            return_value={"Status": "FINISHED"}
        )
        redshift_data.get_statement_result = mock.Mock(
            side_effect=[
                {"Records": [[{"longValue": 10}, {"longValue": 100}]]},
                {"Records": [[{"longValue": 20}, {"longValue": 200}]]},
            ]
        )

        os.environ["REDSHIFT_CLUSTER_ID"] = "test-cluster"

        table_stats = get_all_redshift_table_stats(
            redshift_data, started_means_done=True
        )
        expected_stats = {
            "table1": {"row_count": 10, "max_id": 100},
            "table2": {"row_count": 20, "max_id": 200},
        }
        self.assertEqual(table_stats, expected_stats)

    def test_calculate_delta(self, patched_time_sleep, patched_print):
        # Test case where there are differences and print statement is expected
        redshift_stats = {
            "table1": {"max_id": 110, "row_count": 15},
            "table2": {"max_id": 200, "row_count": 190},
            "table3": {"max_id": 310, "row_count": 305},
        }
        idp_stats = {
            "table1": {"max_id": 100, "row_count": 10},
            "table2": {"max_id": 200, "row_count": 190},
            "table3": {"max_id": 300, "row_count": 300},
        }
        with self.assertLogs() as log:

            calculate_delta(redshift_stats, idp_stats)
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': False, 'max_id_delta': 10, 'count_delta': 5, 'table': 'table1'}",
                log.output[0],
            )
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': True, 'max_id_delta': 0, 'count_delta': 0, 'table': 'table2'}",
                log.output[1],
            )
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': False, 'max_id_delta': 10, 'count_delta': 5, 'table': 'table3'}",
                log.output[2],
            )

        # Test case where there are no differences
        redshift_stats = {
            "table1": {"max_id": 100, "row_count": 10},
            "table2": {"max_id": 200, "row_count": 190},
            "table3": {"max_id": 300, "row_count": 300},
        }
        idp_stats = {
            "table1": {"max_id": 100, "row_count": 10},
            "table2": {"max_id": 200, "row_count": 190},
            "table3": {"max_id": 300, "row_count": 300},
        }
        with self.assertLogs() as log:
            calculate_delta(redshift_stats, idp_stats)
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': True, 'max_id_delta': 0, 'count_delta': 0, 'table': 'table1'}",
                log.output[0],
            )
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': True, 'max_id_delta': 0, 'count_delta': 0, 'table': 'table2'}",
                log.output[1],
            )
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': True, 'max_id_delta': 0, 'count_delta': 0, 'table': 'table3'}",
                log.output[2],
            )

        # Test case where some tables are missing in idp_stats and/or redshift_stats
        redshift_stats = {
            "table1": {"max_id": 110, "row_count": 15},
            "table2": {"max_id": 200, "row_count": 190},
        }
        idp_stats = {
            "table1": {"max_id": 100, "row_count": 10},
            "table3": {"max_id": 300, "row_count": 300},
        }
        with self.assertLogs() as log:
            calculate_delta(redshift_stats, idp_stats)
            self.assertIn(
                "{'name': 'StaleDataCheck', 'success': False, 'max_id_delta': 10, 'count_delta': 5, 'table': 'table1'}",
                log.output[0],
            )

    @mock.patch(
        "stale_data_check.get_all_redshift_table_stats",
        return_value={
            "table1": {"row_count": 10, "max_id": 100},
            "table2": {"row_count": 20, "max_id": 200},
        },
    )
    @mock.patch(
        "stale_data_check.get_idp_stats_from_s3",
        return_value={
            "table1": {"row_count": 10, "max_id": 100},
            "table2": {"row_count": 20, "max_id": 200},
        },
    )
    @mock.patch("stale_data_check.calculate_delta")
    def test_lambda_handler(
        self,
        mock_calculate_delta,
        mock_get_idp_stats,
        mock_get_tables,
        patched_time_sleep,
        patched_print,
    ):
        self.stub_s3_with_content(
            self.BUCKET_NAME, self.INVALID_OBJECT_KEY, self.MAX_ID_TEST_JSON
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

        # Check the correct error message is logged
        self.assertIn(
            f"Invalid file format: {self.INVALID_OBJECT_KEY}. Expected format: YYYY-MM-DD_table_summary_stats.json",
            log.output[0],
        )

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

        # Check the correct error message is logged
        self.assertIn(
            f"{self.OBJECT_KEY}, is a valid file format",
            log.output[0],
        )


if __name__ == "__main__":
    unittest.main()
