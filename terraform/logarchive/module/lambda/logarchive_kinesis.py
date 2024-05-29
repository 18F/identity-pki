"""
For processing data sent to a CloudWatch Logs Destination by CloudWatch Logs Subscription Filters.
The CloudWatch Logs Destination is configured with a Kinesis Data Stream as the recipient.
This Lambda function is configured with a Consumer from the Kinesis Data Stream as its trigger,
in order to support enhanced fan-out and scaling of shards as is necessary.

The following environment variables are used, with default values as listed:

CWLogsPrefix = CloudWatchLogs
S3Bucket = login-gov.logarchive-<ACCT_TYPE>.<ACCT_NUM>-<REGION>

**The code below expects a subscription filter with a naming convention of:
<source_account_id>-<region_name>-<source_service>.
A JSON map can be used as an environment variable to perform additional validation
and parsing based on the subscription filter name and logGroup field if necessary.

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


The code below will gunzip the decoded data and parse the JSON within.
For records whose messageType is DATA_MESSAGE:
1) Determine the S3 path by parsing the subscription filter name and constructing from:
   CWLogsPrefix + source_account_id + region_name + source_service + log_group + log_stream
2) Write the complete Kinesis record as an object to S3 at the constructed path above,
   using 'partitionKey-sequenceNumber' of the record as the S3 object name.

Drop any record whose messageType != DATA_MESSAGE, as these records do not contain any log events.
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
            parsed_filter = re.search(
                r'^(?P<account>\d{12})-(?P<region>\w{2}-\w.*-\w*)-(?P<type>\w*)',
                subscription_filter
                ).groupdict()
            record_data = {
                'accountId': parsed_filter['account'],
                'awsRegion': parsed_filter['region'],
                'logType': parsed_filter['type'],
                'logGroup': data['logGroup'],
                'logStream': data['logStream'],
                'logEvents': data['logEvents']
            }

            events = []

            for logEvent in data.get('logEvents'):
                events.append(json.dumps(logEvent, default=str))

            """
            Assume that all Log Group names either start with /aws[/|-]{logType}/ or
            with no prefix at all. This allows for better organization of Log Groups
            from the same AWS service that have different, unchangeable names/paths
            (e.g. '/aws/rds/' for cluster/instance/postgresql logs,
            vs. 'RDSOSMetrics' for OS level/enhanced monitoring of resources)
            """
            logType = parsed_filter['type']
            logGroupName = re.sub(rf'^/aws[/|\-]{logType}/', '', data['logGroup'])
            
            s3Bucket=os.environ['S3Bucket']
            s3Key="".join([
                os.environ['CWLogsPrefix'], "/", parsed_filter['account'], "/",
                parsed_filter['region'], "/", parsed_filter['type'], "/",
                logGroupName, "/", data['logStream'], "/", partitionKey, "-", sequenceNumber
                ])
            s3Body="\n".join(events)

            boto3.client('s3').put_object(Bucket=s3Bucket,Key=s3Key,Body=s3Body)
            processed_data = base64.b64encode(json.dumps(record_data).encode('utf-8')).decode()
            yield {
                'data': processed_data,
                'result': 'Ok',
                'partitionKey': partitionKey,
                'sequenceNumber' : sequenceNumber
            }
            if os.environ['LogS3Keys'] == 'YES':
                print("Successfully processed record: " + s3Key)
        else:
            yield {
                'result': 'Dropped',
                'partitionKey': partitionKey,
                'sequenceNumber' : sequenceNumber
            }

def lambda_handler(event, context):
    records = list(processRecords(event['Records']))
    return {"records": records}