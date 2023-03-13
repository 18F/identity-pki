import json
import os
import logging
import boto3
import datetime
from botocore.exceptions import ClientError
import re
import time
from datetime import timedelta
from datetime import date

logger = logging.getLogger()
logger.setLevel(logging.INFO)

iam = boto3.client('iam')
ses = boto3.client('ses')

# Environment Variable: RotationPeriod
# The number of days after which a key should be evaluated either for sending notification or change it's status to Inactive
rotationPeriod = int(os.environ['RotationPeriod'])

# Environment Variable: InactivePeriod
# The number of days after which to inactivate keys
# Note: This must be greater than RotationPeriod
oldKeyInactivationPeriod = int(os.environ['InactivePeriod'])

# Environment Variable: RetentionPeriod
# The number of days after which to delete keys that have been rotated and inactivated
# Note: This must be greater than InactivePeriod
# This can be used for future implementation if we intend to give Lambda capability to delete the keys as well
oldKeyDeletionPeriod = int(os.environ['RetentionPeriod'])

# Pre-calculate the rotation and retention cutoff dates
rotationDate = (datetime.datetime.now() - datetime.timedelta(days=rotationPeriod)).date()
inactivationDate = (datetime.datetime.now() - datetime.timedelta(days=oldKeyInactivationPeriod)).date()
deletionDate = (datetime.datetime.now() - datetime.timedelta(days=oldKeyDeletionPeriod)).date()


def lambda_handler(event, context):
    logger.info("Event: " + json.dumps(event))
    print("Event in raw format", event)
    print("Current time", datetime.datetime.now())

    event = json.loads(event['Records'][0]['Sns']['Message'])

    account_id = event['Account']
    user_name  = event['User']
    reason     = event['Reason']

    if user_name:
       process_user(user_name)


def process_user(user_name, force=False):
    lak = iam.list_access_keys(UserName=user_name)
    
    print("Here are the keys for user_name", lak, user_name)
    #print("Here is the AccessKeyMetadata", lak['AccessKeyMetadata'])
    
    #IAM user can have two access keys at a time and we are sorting the keys based on the creation date
    num_keys = 0

    # Active Keys
    active_keys = []

    # Inactive Keys
    inactive_keys = []

    # Oldest Key
    oldest_key = None

    #Email address for sending warning notification to the user directly
    sender_email = "noreply@humans.login.gov"
    realemail = user_name + "@gsa.gov"
    print("real recipient_email", realemail)
    recipient_email = "paul.hirsch" + "@gsa.gov"
    print("recipient_email", recipient_email)



    # Classify all access keys for the current user
    for akm in lak['AccessKeyMetadata']:
        print("akm", akm)
        num_keys += 1
        if oldest_key is None or oldest_key['CreateDate'] > akm['CreateDate']:
            oldest_key = akm
            print("oldest_key", oldest_key)
        if akm['Status'] == 'Active':
            active_keys.append(akm)
        else:
            inactive_keys.append(akm)
       
    num_active = len(active_keys)
    num_inactive = len(inactive_keys)
    
    logger.info("Active: {}".format(num_active))
    logger.info("Inactive: {}".format(num_inactive))
    
    print("rotationDate", rotationDate)
    print("inactivationDate", inactivationDate)
    print("deletionDate", deletionDate)
    
    
    if num_active == 2:
        print("There are 2 active keys")

        # Two active keys. Check the age and status of keys
        classification_1 = classify_date(active_keys[0])
        classification_2 = classify_date(active_keys[1])
  
        logger.info("Classification 1: {}".format(classification_1))
        logger.info("Classification 2: {}".format(classification_2))

        # Two Active Keys
        if classification_1 == "New" or classification_2 == "New":
            # At least one key is new. Handle oldest one according to inactivation/deletion dates
            handle_oldest_key(user_name, recipient_email, sender_email, oldest_key)

        elif classification_1 == "Notify" or classification_2 == "Notify":
            # At least one key is approaching inactivation. Handle oldest one according to inactivation/deletion dates
            handle_oldest_key(user_name, recipient_email, sender_email, oldest_key)
        
        elif classification_1 == "Inactivate" or classification_2 == "Inactivate":
            # At least one key is inactive. Handle oldest one according to inactivation/deletion dates
            handle_oldest_key(user_name, recipient_email, sender_email, oldest_key)

        else:
            # Both keys older than retention date. Delete oldest key(Can be used for future implementation)
            key_to_delete = oldest_key['AccessKeyId']
            logger.info("Delete Key(s): {}".format(key_to_delete))
            #iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete)

    elif num_active == 1 and num_inactive == 1:
        print("There are 1 active and 1 inactive keys")
        # One active and one inactive. Handle active key according to the creation date
        logger.info("Inactive Key(s): {}".format(inactive_keys[0]))
        logger.info("Active Key(s): {}".format(active_keys[0]))
        handle_oldest_key(user_name, recipient_email, sender_email, active_keys[0])
    
    elif num_active == 1 and num_inactive == 0:
        print("There is active key")
        # Single key that is active. 
        classification = classify_date(active_keys[0])
        print("Here is the key classification", classification)
        if classification == "New":
            logger.info("Classification: {}".format(classification))
            logger.info("No key rotation required.")
        else:
            handle_oldest_key(user_name, recipient_email, sender_email, active_keys[0])
            
    elif num_active == 0 and num_inactive > 0:
        print("There is no active key")
        # If no active keys, delete all inactive keys
        for key_to_delete in inactive_keys:
            logger.info("Delete Key(s): {}".format(key_to_delete))
            #Can be enabled in future implementation
            #iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete['AccessKeyId'])
    

def handle_oldest_key(user_name, recipient_email, sender_email, oldest_key):
    classification = classify_date(oldest_key)
    key_to_inactivate = oldest_key['AccessKeyId']
    masked_access_key = mask_access_key(key_to_inactivate)
    key_created_at = oldest_key['CreateDate']
    print("key was created at", key_created_at)
    
    access_keys_age = ((datetime.datetime.now()).date() - key_created_at.date()).days
    print("Age of the key", (access_keys_age) )

    keys_inactivated_days_count = 100 - access_keys_age
    
    keys_inactivated_at = ((datetime.datetime.now()).date() + timedelta(days=keys_inactivated_days_count))


    # The character encoding for the email.
    CHARSET = "UTF-8"

    BODY_HTML = """<html>
    </html>
                """    
    
    print("Here is the oldest key from handle_oldest_key function", oldest_key)
    logger.info("Classification: {}".format(classification))
    
    print("Here is the masked_access_key from inside handle_oldest_key", masked_access_key)


    if classification == "Notify":
        logger.info("Key(s) approaching near inactivation action: {}".format(masked_access_key))
        SUBJECT = ("Your AWS IAM Access Key status will change to Inactive in " + str(keys_inactivated_days_count) + " day(s)")

        BODY_HTML = """<html>
                <head> Dear {user_name}, </head>
                <body>
                <p> Your IAM Access key ending on "{masked_access_key}" is going to be made Inactive at {keys_inactivated_at}. IAM Access key older than 100 days will be made inactive if not rotated.  Please go to <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-AWS-Vault#rotating-aws-keys'>
                 Runbook</a> for directions on rotating the access keys. </p>

                <p> If you are actively using this key to access AWS api calls, you will lose ability to continue doing so when the key's status is changed to Inactive.</p>

                <p> Please note, this rule does not check or modify your ability to access AWS Accounts using AWS Console Password. </p>

                <p>Thank you!</p><br>

                <p> Helpful links: <br>
                <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-AWS-Vault#rotating-aws-keys'>
                 Runbook</a><br>
                 Slack : @login-platform-help<br></p>
                </body>
                </html>
                        """.format(user_name=user_name, masked_access_key=masked_access_key, keys_inactivated_at=keys_inactivated_at) 
         
        send_notification(recipient_email, sender_email, oldest_key, classification, masked_access_key, SUBJECT, BODY_HTML, CHARSET)
        
    elif classification == "Inactivate" or classification == "Delete":
        logger.info("Inactivate Key(s): {}".format(masked_access_key))
        status = invoke_update_access_keys(user_name,key_to_inactivate,"Inactive")
        if status == "Success":
                #iam.update_access_key(UserName=user_name, AccessKeyId=key_to_inactivate, Status='Inactive')
                SUBJECT = ("Your AWS IAM Access key staus has been changed to Inactive")
        
                BODY_HTML = """<html>
                        <head> Dear {user_name}, </head>
                        <body>
                        <p>Your IAM access key with last 4 digits, "{masked_access_key}" has been made inactive:</p>
                        
                        <p>No Action needed if you do not use this key. However, if you wish to regain the access please reach out to @login-platform-help oncall via Slack.</p>
                    
                        <p>Thank you for your understanding!</p><br>

                        <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-AWS-Vault#resetting-vault-generated-credentials'>
                        Runbook</a><br>
                        Slack : @login-platform-help<br></p>
                        </body>
                        </html>
                                """.format(user_name=user_name, masked_access_key=masked_access_key)
        
                send_notification(recipient_email, sender_email, oldest_key, classification, masked_access_key, SUBJECT, BODY_HTML, CHARSET)
        else:
                print("Error occured while assuming IAM role and failed to update access key status")
    
    else:
       print("Current Implementation does not delete the access keys")
    
def classify_date(akm):
    creation_date = akm['CreateDate'].date()
    if creation_date > rotationDate:
        print("key is status New", akm['AccessKeyId'])
        return "New"
    if  rotationDate > creation_date > inactivationDate:
        print("key is status Notify", akm['AccessKeyId'])
        return "Notify"
    if creation_date > inactivationDate:
        print("key status is Inactivate", akm['AccessKeyId'])
        return "Inactivate"
    if creation_date > deletionDate:
        print("key status is Delete", akm['AccessKeyId'])
        return "Inactivate"
    return "Delete"


def invoke_update_access_keys(user_name,key_to_inactivate,status):
    temp_credentials = assume_role_restricted(user_name)
    print("Here are the credentials", temp_credentials)
    action = update_access_keys(temp_credentials, user_name, key_to_inactivate,"Inactive")
    print("Access keys for" + user_name + "made inactive")
    return action
    #return "Success"

def assume_role_restricted(user_name):
    sts      = boto3.client('sts')
    temp_role_arn = os.environ['lambda_temp_role']

    
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:ListAccessKeys",
                    "iam:UpdateAccessKey"
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

def update_access_keys(temp_credentials, user_name, key_to_inactivate, status):
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

        access_keys = iam.list_access_keys(
            UserName=user_name
        )

        print("Access key " + key_to_inactivate + " is going to be made inactivate for the user " + user_name)

        return "Success"

    except ClientError as err:
        print(err.response['Error']['Message'])
        return err
    except Exception as err:
        print(err)
        return err

    #response = iam.update_access_key(
    #            UserName=user_name,
    #            AccessKeyId=key_to_inactivate,
    #            Status='Inactive'
    #        )

    #return response

def mask_access_key(access_key):
    masked_access_key = (re.sub('.', ' ', access_key[:-4]) + access_key[-4:])
    return masked_access_key

def send_notification(recipient_email, sender_email, oldest_key, classification, masked_access_key, SUBJECT, BODY_HTML, CHARSET):
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
