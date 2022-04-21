from __future__ import print_function
import boto3
from botocore.exceptions import ClientError
import os
import json
import csv
from time import sleep
import datetime
from dateutil import parser
import sys

iam = boto3.client('iam')
sns = boto3.client('sns')

account_id = boto3.client("sts").get_caller_identity()["Account"]

def lambda_handler(event, context):
  print(event)
  credential_report = get_credential_report()
  print(credential_report)

  #if(check_password_enabled == "true"): 
  for value in credential_report.items():
 
        test1 = value[1]
        check = test1["password_enabled"]
        print(check)
        if(check == "true"):
           user_name               = test1["user"]
           if((test1["password_last_used"] == "no_information")):
               print("User never logged in the AWS Console, so disabling the access")
               time = (datetime.datetime.now()).date()
               disable_access(user_name, time, account_id)
           else:
            password_last_used_date = test1["password_last_used"]
            password_last_changed_date = test1["password_last_changed"]
        
            used_date = parser.parse(password_last_used_date)                    
            last_used_date = used_date.date()
            print(user_name,"last used their password at", last_used_date)
          
            changed_date = parser.parse(password_last_changed_date)
            last_changed_date = changed_date.date()
            print(user_name, "last changed their password at", last_changed_date)
              
            #action to take by comparing date
            action = compare_time(user_name, last_changed_date, last_used_date, account_id)
            #print("Returned value from function compare_time()", action)

#https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html
#Check the age of password and number of days from last login

def compare_time(user_name, lastchanged, lastlogin, account_id):
 
  password_age = ((datetime.datetime.now()).date() - lastchanged).days
  recent_password_used_age = ((datetime.datetime.now()).date() - lastlogin).days

  print(user_name, "user's password age is", password_age, "days old & was used for the most recent login ",recent_password_used_age, "days ago" )

  if(recent_password_used_age < 120):
    if(90 < password_age <= 100):
        print("Password age between 90-100 days so sending warning notification for user", user_name)
        push_notification(user_name, lastchanged, account_id)
    elif(password_age > 100):
        print("Password age older than 100 days so disabling it for user", user_name)
        disable_access(user_name, lastchanged, account_id)
  else:
    disable_access(user_name, lastlogin, account_id)

#Send notification to user before disabling the console access
def push_notification(user_name, time, account_id):
  notification = " User " + "\"" +  user_name + "\"" + " last activity in AWS Account" + "\"" + account_id + "\"" + " at " + "\"" + time.strftime('%Y-%m-%d') + "\"" + "Console login is disabled after 120 days of missing login activity or if password is not rotated in every 100 days with active login activity. Please rotate any passwords that are about to reach 100 days but if console access in not required, no need to take any action. "
  response = sns.publish (
              TargetArn = os.environ['notification_topic'],
              Message = json.dumps({'default': notification}),
              MessageStructure = 'json'
       )
  print("Notification sent", response)

#Disable console access
def disable_access(user_name, time, account_id):
    try:
        print(" Disabling Console login for user " + "\"" +  user_name + "\"" + " in AWS Account" + "\"" + account_id + "\"" + " .Console login is disabled after 120 days of missing login activity or if password is not rotated in every 100 days with active login activity.")
        iam.delete_login_profile(UserName=user_name)
        print("Login disabled for user " + user_name + " at " + (datetime.datetime.now()).date().strftime('%Y-%m-%d'))
    
    except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchEntity':
                print("After a credential report is created, it is stored for up to four hours. Might be stale data")
            else:
                print("Failed to disable the console login", e.response)

# Request the credential report, download and parse the CSV.
def get_credential_report():
    generate_report = iam.generate_credential_report()
    if generate_report['State'] == 'COMPLETE' :
        try: 
            iam_report = iam.get_credential_report()
            convert = iam_report["Content"].decode("utf-8")   
            convert_lines = convert.split("\n")
            response_reader = csv.DictReader(convert_lines, delimiter=",")
            response_dict = dict(enumerate(list(response_reader)))
            return response_dict
        except ClientError as e:
            print("Unknown error getting Report: " + e.message)
    else:
        sleep(2)
        return get_credential_report()