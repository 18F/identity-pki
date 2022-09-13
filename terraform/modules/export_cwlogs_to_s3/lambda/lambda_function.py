import boto3
import os
from pprint import pprint
import time
import json

logs = boto3.client('logs')
ssm = boto3.client('ssm')
    
# Create a ssm parameter for individual log group
def custom_ssm_name(log_group_name):
    new_name = ("/export-cwlogs-s3%s" % log_group_name)
    print(new_name)
    return new_name

def lambda_handler(event, context):
    input_log_groups = os.environ["CW_LogGroup"]
    log_groups_to_export = json.loads(input_log_groups)
    print("Cloudwatch Log Groups to export to: ",log_groups_to_export)

    for log_group_name in log_groups_to_export:
        #create ssm parameter for storing time of export
        ssm_parameter_name = custom_ssm_name(log_group_name)
        print("ssm parameter name", ssm_parameter_name)
        try:
            ssm_response = ssm.get_parameter(Name=ssm_parameter_name)
            ssm_value = ssm_response['Parameter']['Value']
        except ssm.exceptions.ParameterNotFound:
            ssm_value = "0"
        
        export_to_time = int(round(time.time() * 1000))
        
        print("--> Exporting %s to %s" % (log_group_name, os.environ['S3_BUCKET']))
        
        if export_to_time - int(ssm_value) < (24 * 60 * 60 * 1000):
            # Last export of the log group has not been 24 hrs 
            print("    Export is skipped if last one was completed less than 24hrs")
            continue
             
        try:
            response = logs.create_export_task(
                logGroupName=log_group_name,
                fromTime=int(ssm_value),
                to=export_to_time,
                destination=os.environ['S3_BUCKET'],
                destinationPrefix=os.environ['AWS_ACCOUNT'] + '/' + log_group_name.strip('/')
            )
            taskId = (response['taskId'])

            print("    Task created: %s" % taskId)
            
            status = 'RUNNING'
            while status in ['RUNNING','PENDING']:   
                response_desc = logs.describe_export_tasks(
                    taskId=taskId
                )
                time.sleep(5)
                status = response_desc['exportTasks'][0]['status']['code']
            
            if status == 'COMPLETED':
                print("    Task completed")
                ssm_response = ssm.put_parameter(
                    Name=ssm_parameter_name,
                    Type="String",
                    Value=str(export_to_time),
                    Overwrite=True)

            
        except Exception as e:
            print("    Error exporting %s: %s" % (log_group_name, getattr(e, 'message', repr(e))))
            break
