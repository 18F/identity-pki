import json
import urllib.parse
import boto3
import gzip

s3 = boto3.client('s3')

# Take an event from the logEvents array in a CloudWatch log object and transform it into its own log object:
#   - Add all fields from the parent Cloudwatch log 
#   - Rewrite messages from workers.log as json
def transform_log_event(logEvent):
    try:
        newLogEvent = json.loads(logEvent['message'])
    except ValueError:
        newLogEvent = {'name': logEvent['message'].replace("\n", ' ')}

    return json.dumps(newLogEvent)


def lambda_handler(event, context):

    # Get the bucket name and  object key from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')


    try:
        # Get the object, unzip/decode it and split the objects into their own lines 
        # TODO - This reads the entire file into RAM - Might be too big!
        # We may need to do some chunking:
        # https://medium.com/@analytics-vidhya/6078d0e2b9df
        file = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    except Exception as e:
            print(e)
            print(('Error getting object {} from bucket {}. '
                   'Make sure they exist and your bucket is in '
                   'the same region as this function.').format(key, bucket))
            raise e

    logs = gzip.decompress(file).decode('UTF-8').replace("}{", "}\n{").splitlines()

    # Loop through each log, extract and transform each log event, then append them to new_logs
    new_logs = []

    for log in logs:
        parent = json.loads(log)

        for logEvent in parent['logEvents']:
            new_logs.append(transform_log_event(logEvent))

    # Format the new logs as newline separated json
    new_file = "\n".join(new_logs)

    # Create new key path and append file extension
    new_key = key.replace('logs/', 'athena/') + ".ndjson"

    # Put the new file back into s3
    try:
        return s3.put_object(Bucket=bucket, Key=new_key, Body=str(new_file))

    except Exception as e:
        print(e)
        print(('Error putting object {} into bucket {}. '
               'Make sure they exist and your bucket is in '
               'the same region as this function.').format(key, bucket))
        raise e

