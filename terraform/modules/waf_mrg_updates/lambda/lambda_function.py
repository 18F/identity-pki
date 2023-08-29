import json
import logging
import os
import botocore.vendored.requests as requests
import urllib.request
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
sns = boto3.client("sns")
account_id = boto3.client("sts").get_caller_identity()["Account"]


def send_message_to_sns(message):
    # Sending notification to SNS#
    print("Hi from within send_message_to_sns function", message)
    sns_topic = os.environ["notification_topic"]
    print("Here is the topic", sns_topic)
    subject = message["Subject"] 
    msg = message["Message"]
    timestamp = message["Timestamp"]
    rg_version = message["MessageAttributes"]["major_version"]["Value"]

    final_msg = (
        subject + '\n'
        + "Message: "
        + "\""
        + msg 
        + "\""
        + "\nTimestamp: "
        + timestamp + '\n'
        + "Major_version: "
        + rg_version
    )
    
    response = sns.publish(
        TargetArn=sns_topic,
        Message=json.dumps({"default": (final_msg)}),
        MessageStructure="json",
    )
    print("Here is the response", response)


def lambda_handler(event, context):
    logger.info("Message: " + str(event))

    payload = event["Records"][0]["Sns"]
    response = send_message_to_sns(payload)
    return response