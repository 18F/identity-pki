## This Lambda function sends an alert to slack in case the number of SMS messages (count) exceed 
## a threshold for a country with the exeception of US, Puerto Rico, Mexico and Canada. 

import boto3
from datetime import datetime, timedelta
import time
import json
import os

ignored_countries = '[' + ",".join(
    map(lambda item: '\"' + item + '\"', os.environ['ignored_countries'].split(','))) + ']'
print(ignored_countries)
query = "fields @timestamp, @message | filter attributes.iso_country_code not in {0} | filter ispresent(" \
        "attributes.iso_country_code) | stats count() as count by attributes.iso_country_code,bin(1h) | sort count " \
        "desc".format(ignored_countries)

print(query)
# query = "fields @timestamp, @message | filter attributes.iso_country_code not in [\"US\",\"PR\",\"MX\",\"CA\"] | filter ispresent(attributes.iso_country_code) | stats count() as count by attributes.iso_country_code,bin(1h) | sort count desc"

logs_client = boto3.client('logs')
sns_client = boto3.client('sns')
log_group = '/aws/lambda/pinpoint_event_logger'
account_id = boto3.client("sts").get_caller_identity()["Account"]

def lambda_handler(event, context):

    start_query_response = logs_client.start_query(
        logGroupName=log_group,
        startTime=int((datetime.today() - timedelta(hours=1)).timestamp()),
        endTime=int(datetime.now().timestamp()),
        queryString=query,
    )

    query_id = start_query_response['queryId']

    response = None

    while response is None or response['status'] == 'Running':
        print('Waiting for query to complete ...')
        time.sleep(1)
        response = logs_client.get_query_results(
            queryId=query_id
        )
    print(response)

    for i in range(len(response['results'])):
        message, can_send = parse_message_data(response['results'][i])
        if can_send is True:
            # send message to SNS topic
            sns_publish_response = sns_client.publish(
                TopicArn=os.environ['notification_topic'], 
                Message=json.dumps({'default': message}),
                MessageStructure='json',
            )
            print(sns_publish_response)


def parse_message_data(log_data):
    can_send = False
    message = ''
    count = ''
    country = ''
    for i in range(len(log_data)):
        field = log_data[i]['field']
        value = log_data[i]['value']
        if field == 'attributes.iso_country_code':
            country = value
        if field == 'count':
            count = value
            if int(value) > int(os.environ['sms_limit']):
                can_send = True
                message = "High SMS send rate detected for " + country + " with an hourly count of " + count +" SMS messages, in AWS Account: " + account_id + " - Runbook: " + os.environ['runbook_url']
                # print(message)
    return message, can_send