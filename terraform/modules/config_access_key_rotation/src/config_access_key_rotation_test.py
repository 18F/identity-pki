import os
import unittest
import boto3
from moto import mock_aws
from unittest import mock
from .config_access_key_rotation import lambda_handler


class TestConfigAccessKeyRotation(unittest.TestCase):
    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "RotationPeriod": "80",
            "InactivePeriod": "90",
            "RetentionPeriod": "100",
            "temp_role_arn": "temp:role:arn:12345676890",
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_lambda_handler(self, patched_print):
        self.mock_iam()

        lambda_handler(event={}, context={})

        self.assertPrinted(
            patched_print,
            "recipient_email user.dot.one@gsa.gov",
            "uses the email from iam tags",
        )

        self.assertPrinted(
            patched_print,
            "recipient_email user2@gsa.gov",
            "falls back to username email",
        )

    def assertPrinted(self, patched_print, expected, message):
        did_print = None
        try:
            did_print = next(
                True
                for call in patched_print.call_args_list
                if expected in " ".join(str(arg) for arg in call.args)
            )
        except StopIteration:
            pass

        self.assertIsNotNone(did_print, message)

    def mock_iam(self):
        iam = boto3.client("iam")

        iam.create_user(
            UserName="user1", Tags=[{"Key": "email", "Value": "user.dot.one@gsa.gov"}]
        )
        iam.create_user(UserName="user2")
