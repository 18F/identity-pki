import boto3
import json
import os
from botocore.exceptions import ClientError

support = boto3.client('support', region_name='us-east-1')
sns = boto3.client('sns')

account_id = boto3.client("sts").get_caller_identity()["Account"]

def lambda_handler(event, context):
    try:
        ta_available_checks = support.describe_trusted_advisor_checks(language='en')
        #Get checkIds for the category, service_limits
        for checks in (ta_available_checks['checks']):
            if(checks['category']=='service_limits'):
                refresh_status = support.describe_trusted_advisor_check_refresh_statuses(
                        checkIds=[ checks['id']]
                        )
                status = refresh_status['statuses'][0]['status']
                #print("Current status of service_limits " +  checks['id']  + " is " +  status)
                ##check the refresh status for each check_ids
                if(status == "success"):
                    check_result = support.describe_trusted_advisor_check_result(
                    checkId=checks['id'],
                    language='en'
                    )
                    test_list = check_result['result']['flaggedResources']
                    time_stamp = check_result['result']['timestamp']
                    for item in test_list:
                        if(item['status'] != "ok"):
                           print((item['metadata']))
                           msg = (item['metadata'])
                           msg1 = "Limit-Details: " + "{ Status:" + msg[5] + ", Current Usage:" + msg[4] + ", Limit Name:" + msg[2] + ", Region:" + msg[0] + ", Service :" + msg[1] + ", Limit Amount:" + msg[3] + "}" 
                           send_message_to_sns(account_id,time_stamp,msg1)
        
    except: 
        print('Failed to query against Trusted Advisor')
                
def send_message_to_sns(account_id,time_stamp,message):
#Sending notification to SNS#
    sns_topic_list = json.loads(os.environ['notification_topic'])
    for item in sns_topic_list:
         notification = "AWS-Account: " + account_id + " || " + "Timestamp: " + time_stamp + " || " + message
         response = sns.publish (
              TargetArn = item,
              Message = json.dumps({'default': notification}),
              MessageStructure = 'json'
         )
         print(response) 
