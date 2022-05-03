from __future__ import print_function
import boto3
from botocore.exceptions import ClientError

support = boto3.client('support', region_name='us-east-1')

def lambda_handler(event, context):
    try:
        ta_available_checks = support.describe_trusted_advisor_checks(language='en')
        for checks in ta_available_checks['checks']:
            try:
                support.refresh_trusted_advisor_check(checkId=checks['id'])
                print('Refreshing check: ' + checks['name'])
            except ClientError:
                print('Cannot refresh check: ' + checks['name'])
                continue
    except:
        print('Failed refreshing at this moment')

if __name__ == '__main__':
    lambda_handler('event', 'context')
