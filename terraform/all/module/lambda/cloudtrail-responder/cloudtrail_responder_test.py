import os
import unittest
import json
import boto3
import botocore
import logging
from moto import mock_aws
from unittest import mock


class TestCloudTrailResponder(unittest.TestCase):
    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-east-1",
            "TRAIL_DETAILS": json.dumps(
                {
                    "NAME": "example-trail",
                    "LOG_GROUP": "arn:aws:logs:us-east-1:123456789012:log-group:CloudTrail/DefaultLogGroup:*",
                    "LOG_ROLE": "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role",
                    "LOG_FILE_VALIDATION": True,
                    "INCLUDE_GLOBAL_SERVICE_EVENTS": True,
                    "IS_MULTI_REGION": True,
                    "S3_BUCKET_NAME": "example-trail-bucket",
                }
            ),
        },
        clear=True,
    )
    @mock_aws
    def mock_environment(self):
        from cloudtrail_responder import TrailDetails, restart_cloudtrail_logging

        s3 = boto3.client("s3")
        cloudwatch = boto3.client("logs")
        self.cloudtrail_client = boto3.client("cloudtrail")
        self.trail_details = TrailDetails()
        iam = boto3.client("iam")
        cloudwatch.create_log_group(
            logGroupName=self.trail_details.log_group.split(":")[-2]
        )

        assume_role_policy = json.dumps(
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "CloudTrailAssumeRole",
                        "Effect": "Allow",
                        "Principal": {"Service": "cloudtrail.amazonaws.com"},
                        "Action": "sts:AssumeRole",
                    }
                ],
            }
        )

        iam.create_role(
            RoleName=self.trail_details.log_role.split("/")[-1],
            AssumeRolePolicyDocument=assume_role_policy,
        )

        s3.create_bucket(
            Bucket=self.trail_details.s3_bucket_name,
        )
        self.cloudtrail_client.create_trail(
            Name=self.trail_details.name,
            CloudWatchLogsLogGroupArn=self.trail_details.log_group,
            CloudWatchLogsRoleArn=self.trail_details.log_role,
            EnableLogFileValidation=self.trail_details.log_file_validation,
            IncludeGlobalServiceEvents=self.trail_details.global_service_events,
            IsMultiRegionTrail=self.trail_details.is_multi_region,
            S3BucketName=self.trail_details.s3_bucket_name,
        )

        restart_cloudtrail_logging(self.trail_details)
        initTrail = self.cloudtrail_client.get_trail(Name=self.trail_details.name)
        initTrailStatus = self.cloudtrail_client.get_trail_status(
            Name=self.trail_details.name
        )

        self.assertEqual(
            initTrail["Trail"]["Name"],
            self.trail_details.name,
            "Inital trail is available",
        )
        self.assertTrue(initTrailStatus["IsLogging"], "Inital trail is logging")

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-east-1",
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_restart_cloudtrail_logging(self, patched_print):
        self.mock_environment()
        from cloudtrail_responder import restart_cloudtrail_logging

        trailObject = self.trail_details
        cloudtrail = self.cloudtrail_client

        self.cloudtrail_client.stop_logging(Name=trailObject.name)

        status = cloudtrail.get_trail_status(Name=trailObject.name)

        self.assertFalse(status["IsLogging"], "Trail is not logging")

        restart_cloudtrail_logging(trailObject)

        status = cloudtrail.get_trail_status(Name=trailObject.name)

        self.assertTrue(status["IsLogging"], "Trail has resumed logging")

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-east-1",
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_rebuild_cloudtrail(self, patched_print):
        self.mock_environment()
        from cloudtrail_responder import rebuild_cloudtrail

        trail = self.trail_details
        cloudtrail = self.cloudtrail_client

        originalTrail = cloudtrail.get_trail(Name=trail.name)["Trail"]

        cloudtrail.delete_trail(
            Name=trail.name,
        )

        with self.assertRaises(botocore.exceptions.ClientError):
            cloudtrail.get_trail_status(Name=trail.name)

        rebuild_cloudtrail(trail)

        newTrail = cloudtrail.get_trail(Name=trail.name)["Trail"]
        newTrailStatus = cloudtrail.get_trail_status(Name=trail.name)

        self.assertEqual(originalTrail["Name"], newTrail["Name"])
        self.assertEqual(originalTrail["S3BucketName"], newTrail["S3BucketName"])
        self.assertEqual(
            originalTrail["IsMultiRegionTrail"], newTrail["IsMultiRegionTrail"]
        )
        self.assertEqual(
            originalTrail["IncludeGlobalServiceEvents"],
            newTrail["IncludeGlobalServiceEvents"],
        )
        self.assertEqual(
            originalTrail["LogFileValidationEnabled"],
            newTrail["LogFileValidationEnabled"],
        )
        self.assertEqual(
            originalTrail["CloudWatchLogsLogGroupArn"],
            newTrail["CloudWatchLogsLogGroupArn"],
        )
        self.assertEqual(
            originalTrail["CloudWatchLogsRoleArn"],
            newTrail["CloudWatchLogsRoleArn"],
        )

        self.assertTrue(newTrailStatus["IsLogging"], "Trail has resumed logging")

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-east-1",
            "SNS_TOPIC": "arn:aws:sns:us-east-1:123456789012:alarm_topic",
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_send_message(self, patched_print):
        from cloudtrail_responder import send_message

        self.mock_sns()

        event = self.create_event("StopLogging")

        send_message(event["detail"])

    def mock_sns(self):
        sns_client = boto3.client("sns")
        sns_client.create_topic(Name=os.environ["SNS_TOPIC"].split(":")[-1])

    def create_event(self, eventType: str):
        return {
            "detail-type": "AWS API Call via CloudTrail",
            "source": "aws.cloudtrail",
            "Region": "us-east-1",
            "Time": "2024-05-08T19:27:56Z",
            "detail": {
                "eventSource": "cloudtrail.amazonaws.com",
                "eventTime": "2024-05-08T19:27:56Z",
                "eventName": str(eventType),
                "eventVersion": "1.10",
                "awsRegion": "us-east-1",
                "userIdentity": {
                    "type": "AssumedRole",
                    "principalId": "AROB5LMD5GC4VXMVIU2ZE:test.user",
                    "arn": "arn:aws:sts::123456789012:assumed-role/FullAdministrator/test.user",
                    "accountId": "123456789012",
                    "sessionContext": {
                        "sessionIssuer": {
                            "type": "Role",
                            "arn": "arn:aws:iam::123456789012:role/FullAdministrator",
                            "accountId": "123456789012",
                            "userName": "FullAdministrator",
                        },
                        "attributes": {
                            "creationDate": "2024-05-08T19:27:56Z",
                            "mfaAuthenticated": "true",
                        },
                    },
                },
            },
        }

    @mock.patch.dict(
        os.environ,
        {
            "AWS_DEFAULT_REGION": "us-east-1",
            "SNS_TOPIC": "arn:aws:sns:us-east-1:123456789012:alarm_topic",
            "DEBUG": "TRUE",
            "TRAIL_DETAILS": json.dumps(
                {
                    "NAME": "example-trail",
                    "LOG_GROUP": "arn:aws:logs:us-east-1:123456789012:log-group:CloudTrail/DefaultLogGroup:*",
                    "LOG_ROLE": "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role",
                    "LOG_FILE_VALIDATION": True,
                    "INCLUDE_GLOBAL_SERVICE_EVENTS": True,
                    "IS_MULTI_REGION": True,
                    "S3_BUCKET_NAME": "example-trail-bucket",
                }
            ),
        },
        clear=True,
    )
    @mock.patch("builtins.print")
    @mock_aws
    def test_lambda_handler(self, patched_print):
        self.mock_environment()
        self.mock_sns()
        from cloudtrail_responder import (
            lambda_handler,
        )

        logger = logging.getLogger()

        def run_lambda_handler_with_event(
            eventDetails,
            restart: bool,
            rebuild: bool,
            denied: bool,
        ):
            with self.assertLogs(logger, level="DEBUG") as logs:
                lambda_handler(eventDetails, "")
                mergedLogs = "".join(logs.output)
                self.assertIn("Started by event:", mergedLogs)
                self.assertIn("Trail Information...", mergedLogs)

                if rebuild:
                    self.assertIn("Rebuilding Cloudtrail...", mergedLogs)
                if restart:
                    self.assertIn("Starting Logging...", mergedLogs)
                if denied:
                    self.assertIn("Event was denied.", mergedLogs)

        stopEvent = self.create_event("StopLogging")

        run_lambda_handler_with_event(stopEvent, True, False, False)

        deleteEvent = self.create_event("DeleteTrail")

        run_lambda_handler_with_event(deleteEvent, True, True, False)

        accessDeniedEvent = self.create_event("StopLogging")
        accessDeniedEvent["detail"]["errorCode"] = "AccessDenied"
        accessDeniedEvent["detail"]["errorMessage"] = (
            "User is not allowed to perform StopLogging"
        )

        run_lambda_handler_with_event(accessDeniedEvent, False, False, True)
