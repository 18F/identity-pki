"""
For processing data sent to a CloudWatch Logs Destination by CloudWatch Logs subscription filters.
The CloudWatch Logs Destination is configured with the Kinesis Stream as the recipient.
This Lambda function is configured with a Kinesis Data Stream Trigger.

The following environment variables are used:
CWLogsPrefix = CloudWatchLogs
S3Bucket = central-logging-bucket

**The code below expects a subscription filter with a naming convention of: <source_account_id>-<region_name>-<source_service>. A JSON map
can be used as an environment variable to perform additional validation and parsing based on the subscription filter name and logGroup field if necessary.

{
  "messageType": "DATA_MESSAGE",
  "owner": "123456789012",
  "logGroup": "log_group_name",
  "logStream": "log_stream_name",
  "subscriptionFilters": [
    "subscription_filter_name"
  ],
  "logEvents": [
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208016,
      "message": "log message 1"
    },
    {
      "id": "01234567890123456789012345678901234567890123456789012345",
      "timestamp": 1510109208017,
      "message": "log message 2"
    }
    ...
  ]
}


The code below will:

1) Gunzip the decoded data
2) Parse the json
3) For records whose messageType is DATA_MESSAGE:
4) Determine the path for writing to S3 by parsing the subscription filter name and constructing a path like the following example:
 central-logging-bucket/AWSLogs/CloudWatchLogs/012345678901/us-west-2/lambda/aws/lambda/my-test-function/2023/12/08/[$LATEST]030c172119c54f68b405452dc6270dd837363077163517246583793192107279329791719367945223012352/
5) Extract the individual log events from the logEvents field, and write those events as individual objects to S3.
6) Set the result to Dropped for any record whose messageType is not DATA_MESSAGE, these records do not contain any log events.


"""

import base64
import json
import gzip
import io
import boto3
import re
import os

def processRecords(records):
   
    for r in records:
        event_data = base64.b64decode(r['kinesis']['data'])
        iodata = io.BytesIO(event_data)
        with gzip.GzipFile(fileobj=iodata, mode='r') as f:
            data = json.loads(f.read().decode())
        partitionKey = r['kinesis']['partitionKey']
        sequenceNumber = r['kinesis']['sequenceNumber']
       
        """
        CONTROL_MESSAGE are sent by CWL to check if the subscription is reachable.
        They do not contain actual data.
        """
        if data['messageType'] == 'CONTROL_MESSAGE':
            yield {
                'result': 'Dropped',
                'partitionKey': partitionKey,
                'sequenceNumber' : sequenceNumber
            }
        elif data['messageType'] == 'DATA_MESSAGE':
            subscription_filter = data['subscriptionFilters'][0]
            parsed_filter = re.search(r'^(?P<account>\d{12})-(?P<region>\w{2}-\w.*-\w*)-(?P<type>\w*)', subscription_filter).groupdict()
            record_data = {
                'accountId': parsed_filter['account'],
                'awsRegion': parsed_filter['region'],
                'logType': parsed_filter['type'],
                'logGroup': data['logGroup'],
                'logStream': data['logStream'],
                'logEvents': data['logEvents']                
            }
            for logEvent in data.get('logEvents'):
                boto3.client('s3').put_object(
                    Bucket=os.environ['S3Bucket'],
                    Key="".join([os.environ['CWLogsPrefix'], "/", parsed_filter['account'], "/", parsed_filter['region'], "/", parsed_filter['type'], data['logGroup'], "/", data['logStream'], "/", logEvent['id']]),
                    Body=json.dumps(logEvent, default=str)
                    )
            processed_data = base64.b64encode(json.dumps(record_data).encode('utf-8')).decode()
            yield {
                'data': processed_data,
                'result': 'Ok',
                'partitionKey': partitionKey,
                'sequenceNumber' : sequenceNumber
            }
        else:
            yield {
                'result': 'Dropped',
                'partitionKey': partitionKey,
                'sequenceNumber' : sequenceNumber
            }

def handler(event, context):
    records = list(processRecords(event['Records']))
    return {"records": records}