import os
import unittest
import boto3
from moto import mock_aws
from unittest import mock
from config_access_key_rotation import lambda_handler


class TestConfigAccessKeyRotation(unittest.TestCase):
    ENV_VARS = {
        "AWS_DEFAULT_REGION": "us-west-2",
        "RotationPeriod": "80",
        "InactivePeriod": "90",
        "RetentionPeriod": "100",
        "temp_role_arn": "temp:role:arn:12345676890",
        "users_to_ignore": "ses-smtp",
    }

    @mock.patch.dict(os.environ, ENV_VARS, clear=True)
    @mock.patch("builtins.print")
    @mock_aws
    def test_lambda_handler(self, patched_print):
        self.mock_iam(
            users=[
                {
                    "UserName": "user1",
                    "Tags": [{"Key": "email", "Value": "user.dot.one@gsa.gov"}],
                },
                {"UserName": "user2"},
            ],
        )

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

    @mock.patch.dict(os.environ, ENV_VARS, clear=True)
    @mock.patch("builtins.print")
    @mock_aws
    def test_lambda_handler_skips_users(self, patched_print):
        self.mock_iam(
            users=[{"UserName": "ses-smtp"}],
        )

        lambda_handler(event={}, context={})

        self.assertPrinted(
            patched_print,
            "Skipping user from ignore list UserName=ses-smtp",
            "skips SES user",
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

    def mock_iam(self, users):
        iam = boto3.client("iam")

        for user in users:
            iam.create_user(**user)
