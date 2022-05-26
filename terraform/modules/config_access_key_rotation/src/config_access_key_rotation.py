import json
import os
import logging
import boto3
import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

iam = boto3.client('iam')

# Environment Variable: RotationPeriod
# The number of days after which a key should be rotated
rotationPeriod = int(os.environ['RotationPeriod'])

# Environment Variable: InactivePeriod
# The number of days after which to inactivate keys that had been rotated
# Note: This must be greater than RotationPeriod
oldKeyInactivationPeriod = int(os.environ['InactivePeriod'])

# Environment Variable: RetentionPeriod
# The number of days after which to delete keys that have been rotated and inactivated
# Note: This must be greater than InactivePeriod
oldKeyDeletionPeriod = int(os.environ['RetentionPeriod'])

# Pre-calculate the rotation and retention cutoff dates
rotationDate = (datetime.datetime.now() - datetime.timedelta(days=rotationPeriod)).date()
inactivationDate = (datetime.datetime.now() - datetime.timedelta(days=oldKeyInactivationPeriod)).date()
deletionDate = (datetime.datetime.now() - datetime.timedelta(days=oldKeyDeletionPeriod)).date()

def process_user(user_name, force=False):
    """Rotate access keys for a user.

    Inactive keys will be deleted
    Users with no active access keys will not be processed
    Users with an access key older than the rotation date will have a new key created and stored in ASM, deleting the oldest key if necessary.
    Users with an active access key older than the inactivation date, and an active access key newer than the rotation date will have the oldest key inactivated.
    Users with an inactive access key older than the deletion period, and an active access key newer than the rotation date will have the oldest key deleted
    On a single run of this lambda, a key will only move from active to inactive or inactive to deleted.
    """
    lak = iam.list_access_keys(UserName=user_name)

    num_keys = 0

    # Active Keys
    active_keys = []

    # Inactive Keys
    inactive_keys = []

    # Oldest Key
    oldest_key = None

    # Classify all access keys for the current user
    for akm in lak['AccessKeyMetadata']:
        num_keys += 1
        if oldest_key is None or oldest_key['CreateDate'] > akm['CreateDate']:
            oldest_key = akm
        if akm['Status'] == 'Active':
            active_keys.append(akm)
        else:
            inactive_keys.append(akm)

    # logger.info("Active Key(s): {}".format(active_keys))
    # logger.info("Inactive Key(s): {}".format(inactive_keys))

    num_active = len(active_keys)
    num_inactive = len(inactive_keys)

    logger.info("Active: {}".format(num_active))
    logger.info("Inactive: {}".format(num_inactive))

    # if force:
    #     # Rotation of user is forced for testing
    #     if num_active == 2:
    #         # Two active keys. Delete oldest and rotate
    #         key_to_delete = oldest_key['AccessKeyId']
    #         iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete)

    if num_active == 2:
        # Two active keys. Delete oldest and rotate
        classification_1 = classify_date(active_keys[0])
        classification_2 = classify_date(active_keys[1])
        logger.info("Classification 1: {}".format(classification_1))
        logger.info("Classification 2: {}".format(classification_2))
        # Two Active Keys
        if classification_1 == "New" or classification_2 == "New":
            # At least one key is new. Handle oldest one according to inactivation/deletion dates
            handle_oldest_key(user_name, oldest_key)
        else:
            # Both keys older than rotation date. Delete oldest and create new
            key_to_delete = oldest_key['AccessKeyId']
            logger.info("Delete Key(s): {}".format(key_to_delete))
            #iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete)

    elif num_active == 1 and num_inactive == 1:
        # One active and one inactive. Handle inactive key according to inactivation/deletion dates
        logger.info("Inactive Key(s): {}".format(inactive_keys[0]))
        handle_oldest_key(user_name, inactive_keys[0])

    elif num_active == 1 and num_inactive == 0:
        # Single key that is active. Rotate if necessary.
        classification = classify_date(active_keys[0])
        if classification == "New":
            logger.info("Classification: {}".format(classification))
            logger.info("No key rotation required.")
        else:
            handle_oldest_key(user_name, active_keys[0])
            logger.info("Key made inactive or deleted.")

    elif num_active == 0 and num_inactive > 0:
        # If no active keys, delete all inactive keys
        for key_to_delete in inactive_keys:
            logger.info("Delete Key(s): {}".format(key_to_delete))
            #iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete['AccessKeyId'])

def classify_date(akm):
    creation_date = akm['CreateDate'].date()
    if creation_date > rotationDate:
        return "New"
    if creation_date > inactivationDate:
        return "Rotate"
    if creation_date > deletionDate:
        return "Inactivate"
    return "Delete"

def handle_oldest_key(user_name, oldest_key):
    classification = classify_date(oldest_key)
    logger.info("Classification: {}".format(classification))

    if classification == "Inactivate":
        key_to_inactivate = oldest_key['AccessKeyId']
        logger.info("Inactivate Key(s): {}".format(key_to_inactivate))
        #iam.update_access_key(UserName=user_name, AccessKeyId=key_to_inactivate, Status='Inactive')
    elif classification == "Delete":
        key_to_delete = oldest_key['AccessKeyId']
        logger.info("Delete Key(s): {}".format(key_to_delete))
        #iam.delete_access_key(UserName=user_name, AccessKeyId=key_to_delete)

def lambda_handler(event, context):
    logger.info("Event: " + json.dumps(event))

    # event = event['Records'][0]['Sns']['Message']
    event = json.loads(event['Records'][0]['Sns']['Message'])
    logger.info(event)

    account_id = event['Account']
    user_name  = event['User']
    reason     = event['Reason']

    logger.info("Rotation Date: {}".format(rotationDate))
    logger.info("Inactivation Date: {}".format(inactivationDate))
    logger.info("Deletion Date: {}".format(deletionDate))

    logger.info("Account ID: {}".format(account_id))
    logger.info("Username: {}".format(user_name))
    logger.info("Reason: {}".format(reason))

    if user_name:
        process_user(user_name)

    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }