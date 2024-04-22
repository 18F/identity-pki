import os
import unittest
import boto3
from moto import mock_aws
from unittest import mock
from .config_password_rotation import lambda_handler


class TestConfigPasswordRotation(unittest.TestCase):
    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-west-2",
            "RotationPeriod": "80",
            "InactivePeriod": "90",
            "DeletionPeriod": "100",
            "temp_role_arn": "temp:role:arn:12345676890",
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_lambda_handler(self, patched_print):
        iam = self.mock_iam()

        lambda_handler(event={}, context={}, iam=iam)

        self.assertPrinted(
            patched_print,
            "real recipient_email user.dot.one@gsa.gov",
            "uses the email from iam tags",
        )

        self.assertPrinted(
            patched_print,
            "real recipient_email user2@gsa.gov",
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
        iam.generate_credential_report = mock.Mock(return_value={"State": "COMPLETE"})
        iam.get_credential_report = mock.Mock(
            return_value={
                "Content": """
user,password_enabled,password_last_used,password_last_changed
user1,true,2023-01-01,2023-01-01
user2,true,2023-01-01,2023-01-01
user3,true,no_information,2023-01-01
user4,false,no_information,2023-01-01
""".lstrip().encode(
                    "utf-8"
                ),
            }
        )

        iam.create_user(
            UserName="user1", Tags=[{"Key": "email", "Value": "user.dot.one@gsa.gov"}]
        )
        iam.create_user(UserName="user2")
        iam.create_user(UserName="user3")
        iam.create_user(UserName="user4")

        return iam
