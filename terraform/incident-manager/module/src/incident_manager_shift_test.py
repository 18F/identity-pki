import os
import unittest
import boto3
from moto import mock_aws
from unittest import mock
from datetime import datetime


class IncidentManagerShiftTest(unittest.TestCase):

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
        },
        clear=True,
    )
    def test_compare_time(self):
        from incident_manager_shift import compare_times

        self.assertEqual(
            compare_times(
                datetime(2024, 10, 1, 9, 23, 59), datetime(2024, 10, 1, 9, 23, 25)
            ),
            True,
        )
        self.assertEqual(
            compare_times(
                datetime(2024, 10, 1, 9, 24, 25), datetime(2024, 10, 1, 9, 23, 25)
            ),
            False,
        )

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "SNS_CHANNEL": "arn:aws:sns:us-west-2:123456789012:alarms",
        },
        clear=True,
    )
    @mock_aws
    def test_send_to_slack(self):
        self.mock_sns()
        from incident_manager_shift import send_to_slack

        send_to_slack = send_to_slack("Oncall rotation", "john_doe", "OFF")

        self.assertEqual(send_to_slack["ResponseMetadata"]["HTTPStatusCode"], 200)

    def mock_sns(self):
        sns = boto3.client("sns")

        sns.create_topic(Name="alarms")

        return sns
