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
from datetime import timedelta
from datetime import date

iam = boto3.client('iam')
ses = boto3.client('ses')

account_id = boto3.client("sts").get_caller_identity()["Account"]

def lambda_handler(event, context):
  #print(event)
  credential_report = get_credential_report()
  #print(credential_report)
 

  #if(check_password_enabled == "true"): 
  for value in credential_report.items():
 
        test1 = value[1]
        check = test1["password_enabled"]
        print(check)
        if(check == "true"):
           user_name               = test1["user"]
           if((test1["password_last_used"] == "no_information")):
               print("User " + user_name + " has never logged into the AWS Console. This should be an user who has not onboarded yet")
               continue
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

### SES email template settings ###
  CHARSET = "UTF-8"
  BODY_HTML = """<html>
    </html>
                """  
  
  sender_email = "noreply@humans.login.gov"
  realemail = user_name + "@gsa.gov"
  recipient_email = user_name + "@gsa.gov"
  print("real recipient_email", realemail)

  if(recent_password_used_age < 120):
    if(90 <= password_age <= 100):
        expire_in = 100 - password_age
        expiration_date = ((datetime.datetime.now()).date() + timedelta(days=expire_in))
        print("Expire_in days", expire_in , "days")
        check = expiration_date.strftime('%m/%d/%Y')
        print("Password age between 90-100 days so sending warning notification for user", user_name)
        SUBJECT = ("Your AWS console password is going to expire in " + str(expire_in) + "day(s)")
        BODY_HTML = """<html>
                <head> Dear {user_name}, </head>
                <body>
                <p>Your AWS Console login access is going to be disabled at {check}. Console access is disabled, if there is missing login activity for more than 120 days or if password is not rotated in every 100 days with active login activity. Please go to <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a> for directions on rotating the password. Please note starting 05/18/2023 we will start enforcing this rule so we kindly request in remediating before reaching the mentioned date if not in compliance.</p>

                <p> If you allow your password to expire, you will loose access to the AWS accounts via console. However, this rule does not check or modify your ability to access AWS Accounts using AWS Access Keys. </p>
                <p> If you have any questions, feel free to ping @login-platform-help in slack. </p><br>
                Thank you!<br>
                
                <p> Helpful links: <br>
                <a href='https://console.aws.amazon.com/iam/home?#/security_credentials'>
                 AWS Console link</a><br>
                 Slack: @login-platform-help <br></p>
                </body>
                </html>
                        """.format(user_name=user_name, check=check) 
        send_notification(recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET)

    elif(password_age > 100):
        print("Password age older than 100 days so disabling it for user ", user_name)
        action1 = invoke_console_access(user_name)
        if action1 == "Success":
            SUBJECT = ("Your AWS console password is beyond the required rotation period.")
            BODY_HTML = """<html>
                    <head> Dear {user_name}, </head>
                    <body>
                    <p>Your AWS Console Password is beyond the required rotation period. </p>
                 
                    <p>**If you do not need access to the AWS Console, feel free to ignore this email.**</p>
                    
                    <p> We recommend rotating (updating) AWS Console password in every 100 days in order to be able to continue to log into the AWS console. Console access is disabled, if there is missing login activity for more than 120 days or if password is not rotated in every 100 days with active login activity. Please refer <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a> for directions on rotating the password or please reach out @login-platform-help via Slack for any additional information. Please note starting 05/18/2023 we will start enforcing this rule so we kindly request in remediating before reaching the mentioned date.</p>
                    
                    <p>Thank you for your understanding!</p><br>
               
                    <p> Helpful links: <br>
                    <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                    Runbook</a><br>
                    Slack: @login-platform-help <br></p>
                    </body>
                    </html>
                            """.format(user_name=user_name) 
            send_notification(recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET)
        else: 
            print("Failed to update user's login profile")
  else:
     action = invoke_console_access(user_name)
     if action == "Success":
        SUBJECT = ("Your AWS console password is beyond the required rotation period." )
        BODY_HTML = """<html>
                <head> Dear {user_name}, </head>
                <body>
                <p>Your AWS Console Password is beyond the required rotation period. </p>
         
                <p><p>**If you do not need access to the AWS Console, feel free to ignore this email.**</p>
                
                <p> We recommend rotating (updating) AWS Console password in every 100 days in order to be able to continue to log into the AWS console. Console access is disabled, if there is missing login activity for more than 120 days or if password is not rotated in every 100 days with active login activity. Please refer <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a> for directions on rotating the password or please reach out @login-platform-help via Slack for any additional information. Please note starting 05/18/2023 we will start enforcing this rule so we kindly request in remediating before reaching the mentioned date.</p>
                
                <p>Thank you for your understanding!</p><br>
              
                <p> Helpful links: <br>
                <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a><br>
                 Slack: @login-platform-help <br></p>
                </body>
                </html>
                        """.format(user_name=user_name)
        send_notification(recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET)
     else:
        print("Failed to update user's login profile")
    

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
            print("Unknown error getting Report: " )
    else:
        sleep(2)
        return get_credential_report()



### SES function to send notification ###

def send_notification(recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET):
    try:
        response = ses.send_email(
            Destination={
                'ToAddresses': [
                    recipient_email,
                ],
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': CHARSET,
                        'Data': BODY_HTML
                    }
                },
                'Subject': {
                    'Charset': CHARSET,
                    'Data': SUBJECT
                },
            },
            Source=sender_email,
        )
    
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        print(response['MessageId'])


### Generate temporary role credentials ###
def invoke_console_access(user_name):
    temp_credentials = generate_temp_credentials(user_name)
    #print("Here are the credentials", temp_credentials)
    action = disable_console_access(temp_credentials, user_name)
    print("Console Access for " + user_name + " disabled")
    return action

### Assumed role will have permissions that overlap with the policy below and associated with temp_role_arn
def generate_temp_credentials(user_name):
    sts      = boto3.client('sts')
    temp_role_arn = os.environ['temp_role_arn']
    
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:DeleteLoginProfile",
                    "iam:GetLoginProfile"
                    ],
                "Resource": [
                 "arn:aws:iam::*:user/" + user_name
                ]
            }
        ]
    }
    
    policy_document = json.dumps(policy)
    print("policy_document", policy_document)

    role_session_name = "additionalpolicyfor" + user_name
    print("role_session_name", role_session_name)
    
    session_duration = 3600

    try:
        assumed_role_creds = sts.assume_role(RoleArn=temp_role_arn,
                                                    Policy=policy_document,
                                                    RoleSessionName=role_session_name,
                                                    DurationSeconds=session_duration)
        return assumed_role_creds
    except ClientError as err:
        print(err.response['Error']['Message'])
        return err
    except Exception as err:
        print(err)
        return err

def disable_console_access(temp_credentials, user_name):
    try:
        # Format resulting temporary credentials into JSON
        ACCESS_KEY = temp_credentials["Credentials"]["AccessKeyId"]
        SECRET_KEY = temp_credentials["Credentials"]["SecretAccessKey"]
        SESSION_TOKEN = temp_credentials["Credentials"]["SessionToken"]
        
        iam = boto3.client(
                'iam',
                aws_access_key_id=ACCESS_KEY,
                aws_secret_access_key=SECRET_KEY,
                aws_session_token=SESSION_TOKEN
                )

        profile = iam.get_login_profile(
            UserName=user_name
        )

        print("Here is the user's login profile", profile)

        #response = iam.delete_login_profile(
        #      UserName=user_name
        #)

        print("Console access disabled for the user", user_name)

        return "Success"

    except ClientError as err:
        print(err.response['Error']['Message'])
        return err
    except Exception as err:
        print(err)
        return err