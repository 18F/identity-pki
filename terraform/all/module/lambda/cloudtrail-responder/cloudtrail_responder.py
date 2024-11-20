from __future__ import print_function
import json
import os
import logging
import boto3


sns = boto3.client("sns")
cloudtrail = boto3.client("cloudtrail")
sts_client = boto3.client("sts")
account_id = sts_client.get_caller_identity()["Account"]
logger = logging.getLogger()
logger.setLevel("INFO")


class TrailDetails:
    def __init__(self):
        trail = json.loads(os.environ["TRAIL_DETAILS"])
        self.name = trail["NAME"]
        self.log_group = trail["LOG_GROUP"]
        self.log_role = trail["LOG_ROLE"]
        self.log_file_validation = trail["LOG_FILE_VALIDATION"]
        self.is_multi_region = trail["IS_MULTI_REGION"]
        self.global_service_events = trail["INCLUDE_GLOBAL_SERVICE_EVENTS"]
        self.s3_bucket_name = trail["S3_BUCKET_NAME"]


def lambda_handler(event, context):
    if os.environ["DEBUG"]:
        logger.setLevel("DEBUG")

    logger.info("Started by event: " + json.dumps(event))
    analyze_event_and_respond(event["detail"])

    send_message(event["detail"])


def restart_cloudtrail_logging(trail):
    logger.debug("Starting Logging...")
    start_logging_response = cloudtrail.start_logging(
        Name=trail.name,
    )
    logger.debug(start_logging_response)


def rebuild_cloudtrail(trail):
    logger.debug("Rebuilding Cloudtrail...")
    create_trail_response = cloudtrail.create_trail(
        Name=trail.name,
        CloudWatchLogsLogGroupArn=trail.log_group,
        CloudWatchLogsRoleArn=trail.log_role,
        EnableLogFileValidation=trail.log_file_validation,
        IncludeGlobalServiceEvents=trail.global_service_events,
        IsMultiRegionTrail=trail.is_multi_region,
        S3BucketName=trail.s3_bucket_name,
    )
    logger.debug(create_trail_response)
    restart_cloudtrail_logging(trail)


def analyze_event_and_respond(eventDetails):
    event_name = eventDetails["eventName"]

    trail_details = TrailDetails()
    logging.debug("Trail Information...", trail_details.__dict__)

    if "errorCode" in eventDetails:
        logging.info("Event was denied. Only sending a notification.")
    elif "StopLogging" in event_name:
        restart_cloudtrail_logging(trail_details)
    elif "DeleteTrail" in event_name:
        rebuild_cloudtrail(trail_details)


def send_message(eventDetails):
    sns_topic = os.environ["SNS_TOPIC"]
    message = "\n".join(
        (
            f"*Incident:* Cloud Trail has {eventDetails['eventName']}",
            f"*What happened?* {eventDetails['eventName']}",
            f"*What service?* {eventDetails['eventSource']}",
            f"*Where?* {eventDetails['awsRegion']}",
            f"*When?* {eventDetails['eventTime']}",
            f"*Who?* ```{str(json.dumps(eventDetails['userIdentity'], indent=2))}```",
        )
    )

    if "errorCode" in eventDetails:
        message += "\n" + "\n".join(
            (
                f"*Status:* {eventDetails['errorCode']}",
                f"*Reason:* {eventDetails['errorMessage']}",
            )
        )

    sns_response = sns.publish(
        TopicArn=sns_topic,
        Message=message,
    )

    logger.debug(sns_response)
