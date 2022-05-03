import json
import base64
import boto3
import random
import time
from datetime import datetime
import os

LOG_GROUP_NAME=os.environ['log_group_name']
LOG_STREAM_NAME=os.environ['log_stream_name']

def lambda_handler(event, context):
    seq_token = None
    AWS_REGION = os.environ['region']
    client = boto3.client('logs', region_name=AWS_REGION)
    response = client.describe_log_streams(
        logGroupName=LOG_GROUP_NAME,
        logStreamNamePrefix=LOG_STREAM_NAME
    )
    for record in event['Records']:
       #Kinesis data is base64 encoded so decode here
       payload=json.loads(base64.b64decode(record["kinesis"]["data"]))
       payload['attributes']['destination_phone_number']=payload['attributes']['destination_phone_number'][:6]+"*****"
       print("Decoded payload: " + str(payload))
       log_event = {
            'logGroupName': LOG_GROUP_NAME,
            'logStreamName': LOG_STREAM_NAME,
            'logEvents': [
                {
                    'timestamp': int(round(time.time() * 1000)),
                    'message': str(payload)
                    
                },
            ],
            }
    if 'uploadSequenceToken' in response['logStreams'][0]:
        log_event.update({'sequenceToken': response['logStreams'][0] ['uploadSequenceToken']})
    response = client.put_log_events(**log_event)
    print(response)