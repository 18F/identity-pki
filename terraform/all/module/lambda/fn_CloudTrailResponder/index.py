from __future__ import print_function
import json
import boto3

def lambda_handler(event, context):
    print(json.dumps(event, indent=2))
    cloudtrail = boto3.client('cloudtrail')
    trail_arn = event["detail"]["requestParameters"]["name"]
    name = str(trail_arn.split("/")[1])

    if name == "" or "" == "":

        if "StopLogging" in event["detail"]["eventName"]:
            ct_response = cloudtrail.start_logging(
                Name = trail_arn,
            )
            
        if "DeleteTrail" in event["detail"]["eventName"]:
            name = str(trail_arn.split("/")[1])
            multiRegion = True
            globalService = True
            logValidation = False
            ct_response = cloudtrail.create_trail(
                Name = name,
                CloudWatchLogsLogGroupArn = "",
                CloudWatchLogsRoleArn="",
                EnableLogFileValidation=logValidation,
                IncludeGlobalServiceEvents=globalService,
                IsMultiRegionTrail=multiRegion,
                S3BucketName=""
            )
            ct_response = cloudtrail.start_logging(
                Name = name,
            )
            
        sns_topic = "arn:aws:sns:us-west-2:894947205914:CTResponder"
        
        subject = 'Incident: Cloud Trail has'  +  " " + event["detail"]["eventName"]
        message = "What happened? " + event["detail"]["eventName"] + "\n" \
        "What service? " + event["detail"]["eventSource"] + "\n" \
        "Where? " + event["detail"]["awsRegion"] + "\n" \
        "When? " + event["detail"]["eventTime"] + "\n" \
        "Who? " + str(json.dumps(event["detail"]["userIdentity"], indent=2))
        
        sns = boto3.client('sns')
        sns_response = sns.publish(
            TopicArn = sns_topic,
            Message = message,
            Subject = subject,
            MessageStructure = 'string'
        )
        print(sns_response)
