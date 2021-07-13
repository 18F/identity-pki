#!/usr/bin/env python3 
 # Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
  #
  # Licensed under the Apache License, Version 2.0 (the "License").
  # You may not use this file except in compliance with the License.
  # A copy of the License is located at
  #
  #     http://www.apache.org/licenses/LICENSE-2.0
  #
  # or in the "license" file accompanying this file. This file is distributed
  # on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
  # express or implied. See the License for the specific language governing
  # permissions and limitations under the License.


import boto3
import re
import logging
import sys
import datetime
import base64
import random
import string
import time
import argparse

###### Creating global variables
# OSLevelCommands are the commands which will be attempted on the host OS of the instance in the event that SSM is configured and functional.
OSLevelCommands = ["netstat -ap","lsof"]
#SSM Drain time is the time after a successful SSM message send to wait before quarantining the instance. This may need to eb increased if OS commands above are lengthy
SSM_DRAIN_TIME = 10
# Simple, likely unique identifier for this particular script run as a prefix for files in S3.
RUNIDPREFIX = str(datetime.datetime.utcnow().timestamp())+"/"



def _random_string():
    return ''.join(random.choice(string.ascii_lowercase) for i in range(5))


# Check to see if instance ID is valid. If not exit
# Note that this will need modification if AWS changes the formatting of the instance ID pattern.
def instanceid_is_valid(instance_id):
    if re.match('^i-[a-z0-9]{17}$', instance_id):
        logging.debug('Instance ID is in a valid format. ' + instance_id)
        return True
    else:
        logging.error(
            "Instance ID \"%s\" is invalid. Must enter valid EC2 Instance ID, e.g.: \"i-1a2b3c4d678\"" % instance_id)
        sys.exit()



# Following is used to import Cloudformation exports, as that's the method for passing these uniquely generated items.
"""def retrieve_cft_exports():
    try:
        global BUCKET_NAME
        global SNS_TOPIC
        global SSMIAMRoleForSNS
        global SSMEC2IAMPROFILE
        cft_client = boto3.client('cloudformation')
        thisCFTExports = cft_client.list_exports()
        BUCKET_NAME = ''
        SNS_TOPIC = ''
        SSMIAMRoleForSNS = ''
# This is not elagant coding, but it does demonstrate how to pull each value from the API call return:
        for eachExport in thisCFTExports['Exports']:
            if eachExport['Name'] == 'SecResponseRepositoryS3Bucket':
                BUCKET_NAME = eachExport['Value']
            elif eachExport['Name'] == 'SecResponseMechanismSNSTopic':
                SNS_TOPIC = eachExport['Value']
            elif eachExport['Name'] == 'SSMIAMRoleForSNS':
                SSMIAMRoleForSNS = eachExport['Value']
            elif eachExport['Name'] == 'SecurityResponseEC2InstanceRoleProfile':
                SSMEC2IAMPROFILE = eachExport['Value']
        if BUCKET_NAME == '' or SNS_TOPIC == '' or SSMIAMRoleForSNS == '' or SSMEC2IAMPROFILE == '' :
            message = 'Unable to determine and import required cloudformation exports.'
            send_sns_message(message)
            sys.exit()
        message = 'Successfully determined S3 bucket and SNS topic as: ' + BUCKET_NAME + ' and ' + SNS_TOPIC
        print(message)
    except ValueError as e:
        message = "Unable to determine storage and messaging locations." +  + str(e['ErrorMessage'])
        print(message)
        sys.exit()"""

# Checking to see if instance is part of an ASG. If it is then remove it from ASG
def detach_from_asg(asgClient, instance_id):
    print("Checking to see if instance is part of ASG")
    try:
        response = asgClient.describe_auto_scaling_instances(
            InstanceIds=[
                instance_id
            ]
        )
    except ValueError as e:
        message = 'Unable to describe ASG instances. Raw: ' + str(e['ErrorMessage'])

    if 'AutoScalingInstances' in response and len(response['AutoScalingInstances']) > 0:
        if 'AutoScalingGroupName' in response['AutoScalingInstances'][0]:
            asg_name = response['AutoScalingInstances'][0]['AutoScalingGroupName']
        else:
            message = 'Unable to obtain ASG name... will not be able to deregister instance. Exiting.'
        try:
            response = asgClient.detach_instances(
                InstanceIds=[
                    instance_id,
                ],
                AutoScalingGroupName=asg_name,
                ShouldDecrementDesiredCapacity=False
            )
            message = 'Success in detaching instance ' + instance_id + ' from ASG,' + asg_name
        except ValueError as e:
            message = 'Unable to remove ' + instance_id + ' from ' + asg_name + '. Error: ' + str(e['ErrorMessage'])
    else:
        message = 'Instance ' + instance_id + ' does not seem to be part of an ASG.'
    print(message)
    if SNS_TOPIC:
        send_sns_message(message)


# Preparing instance for snapshot of EBS volumes attached to the instance
def snapshot(ec2Client, instance_id):
    global VPC_ID
    volume_ids = []
    print("Preparing instance for snapshot")

    try:
        instance_describe_metadata = ec2Client.describe_instances(
            InstanceIds=[
                instance_id
            ],
        )
    except ValueError as e:
        message = 'Unable to get instance metadata' + str(e['ErrorMessage'])

    target_instance_data = instance_describe_metadata['Reservations'][0]['Instances'][0]

    # Log and upload instance metadata to S3
    print(target_instance_data)
    ################################################################################
    metadata_file = 'metadata_file-' + instance_id + '.output'
    with open('/tmp/' + metadata_file, 'w') as f:
        f.write(str(target_instance_data))
        f.close()
    data = open('/tmp/' + metadata_file, 'rb')

    upload_to_s3(data, metadata_file, instance_id)

    # Taking snapshot of attached EBS Volume(s)
    if 'BlockDeviceMappings' in target_instance_data and len(target_instance_data['BlockDeviceMappings']) > 0:
        for block_devices in target_instance_data['BlockDeviceMappings']:
            if 'Ebs' in block_devices:
                if 'VolumeId' in block_devices['Ebs']:
                    volume_ids.append(block_devices['Ebs']['VolumeId'])
        message = 'Initial attributes captured. Found EBS volume(s) to snapshot.:' + str(volume_ids)
    else:
        print("No EBS volume found.")

    # Triggering snapshot
    for volume_id in volume_ids:
        try:
            ec2Client.create_snapshot(
                VolumeId = volume_id,
                Description = 'Security Response automated copy of '+volume_id+' for instance '+instance_id
            )
            message = "Created snapshot of volume "+volume_id
        except ValueError as e:
            message = 'Failed to start snapshot for '+volume_id+". Error: "+ str(e['ErrorMessage'])+'\n'

    #we have all the metadata here, so let's capture the VPC_ID for later use as a global
    VPC_ID = instance_describe_metadata['Reservations'][0]['Instances'][0]['VpcId']
    if SNS_TOPIC:
        send_sns_message(message)
    print(message)


# Setting termination protection for the instance. Ensuring nobody can accidently
# terminate the instance.
def set_termination_protection(ec2Client, instance_id):
    print("Setting termination protection for the instance")
    try:
        response = ec2Client.modify_instance_attribute(
            InstanceId=instance_id,
            DisableApiTermination={
                'Value': True
            }
        )
        message = "Termination protection enabled for instance" + instance_id
    except ValueError as e:
        message = "Unable to set Termination protection for instance" + instance_id + str(e['ErrorMessage'])

    print(message)
    if SNS_TOPIC:
        send_sns_message(message)


# Creating isolation security group
def create_isolate_sg(ec2Client, VPC_ID, instance_id):
    print("Creating isolation security group")
    isolateSGCreate=''
    try:
        isolateSGCreate = ec2Client.create_security_group(
            VpcId=VPC_ID,
            GroupName='SecurityContainmentSG-' + instance_id + "-" + _random_string(),
            Description='Isolation SG created during response process.'
        )

        # By default, an open outbound rule is created with SG. Removing that rule
        response = ec2Client.revoke_security_group_egress(
            GroupId=isolateSGCreate['GroupId'],
            IpPermissions=[
                {
                    'IpProtocol': '-1',
                    'IpRanges': [
                        {
                            'CidrIp': '0.0.0.0/0'
                        },
                    ]
                },
            ]
        )
        message = "Isolation security group created"
    except ValueError as e:
        message = 'Unable to create security group ' + str(e['ErrorMessage'])
    print(message)
    if SNS_TOPIC:
        send_sns_message(message)
    return isolateSGCreate['GroupId']



# Attach isolation SG to instance
def isolate_instance(ec2Client, instance_id, VPC_ID, isolateSG):
    try:
        #isolateSG = create_isolate_sg(ec2Client, VPC_ID, instance_id)
        response = ec2Client.modify_instance_attribute(
            InstanceId=instance_id,
            Groups=[isolateSG]
        )
        message = "Isolation successful -- " + str(response)
    except ValueError as e:
        message ='Unable to isolate instance! -- ' + str(e['ErrorMessage'])

    print(message)


# Creating tag and attaching it to the instance
def set_tags(ec2Client, instance_id):
    print("Creating tag for the instance")
    tag_key = "Security"
    tag_value = "Instance quarantined for security containment " + str(datetime.datetime.utcnow())

    try:
        response = ec2Client.create_tags(
            Resources=[instance_id],
            Tags=[
                {'Key': tag_key,
                 'Value': tag_value}
            ]
        )
        message = "Successfully created Security tag"
    except ValueError as e:
        message = "Unable to create tag for the instance" + str(e['ErrorMessage'])
    print(message)

    if SNS_TOPIC:
        send_sns_message(message)


# Taking console screenshot of the instance and uploading it to S3 bucket
def console_screenshot(ec2Client, instance_id):
    print("Getting instance's console screenshot")
    try:
        response = ec2Client.get_console_screenshot(
            InstanceId=instance_id,
            WakeUp=True
        )
        file_name = 'console_screenshot-' + instance_id + '.jpg'
        screenshot = base64.b64decode(response['ImageData'])
        upload_to_s3(screenshot, file_name, instance_id)
        message = "Sucessfuly captured console screenshot. Object name: " + file_name
    except ValueError as e:
        message = "Unable to capture console screenshot" + str(e['ErrorMessage'])
    print(message)

    if SNS_TOPIC:
        send_sns_message(message)


def upload_to_s3(data, filename, iid):
    try:
        s3 = boto3.resource('s3')
        curdt = datetime.datetime.now()
        s3prefix = str(curdt.year)+"-"+str(curdt.hour)+"-"+str(curdt.minute)+":"+str(curdt.second)+"-"+iid+"/"
        response = s3.Bucket(BUCKET_NAME).put_object(Key=s3prefix+filename,
                                                     Body=data, ServerSideEncryption='AES256', ACL='bucket-owner-full-control')
        message = "Successfully uploaded file to bucket " + BUCKET_NAME
    except ValueError as e:
        message = "Unable to upload file to s3 bucket" + str(e['ErrorMessage'])
    print(message)

    if SNS_TOPIC:
        send_sns_message(message)


def send_sns_message(message):
    print('Publishing message to SNS')
    try:
        sns_client = boto3.client('sns', region_name=AREGION)
        sns_client.publish(TargetArn=SNS_TOPIC, Message=message)
        message = "Successfully send message to SNS"
    except ValueError as e:
        message = "unable to send SNS message" + str(e['ErrorMessage'])
    print(message)


#Test to see if SSM has the instance in its managed instance list:
def is_instance_managed_by_SSM(ssm, instance_id):
    #first, we'll determine if the instance is under the influence of SSM to begin:
    #This can be optimized by converting this list of dicts into a more expected dict of instance IDs and then simply finding the key. Requires pandas likely.
    ssmInstanceInformation = ssm.describe_instance_information()
    for thisInstanceInfo in ssmInstanceInformation['InstanceInformationList']:
        if thisInstanceInfo['InstanceId'] == instance_id:
            print("Found instance " + instance_id + " is managed by SSM")
            return True
    #If we can't find this instance in the list that SSM knows about, then don't execute the send commands portion.
    print("Instance " + instance_id + " not found to be controlled by SSM.")
    return False


# Sending SSM Run Command to the instance
def ssm_send_commands(ssm, instance_id):
    try:
        #Add a pause here for a few seconds to allow the instance profile change to iron itself out, or the S3 upload can fail:
        time.sleep(5)

        ACCOUNT_ID = boto3.client('sts').get_caller_identity().get('Account')
        response = ssm.send_command(
            InstanceIds=[
                instance_id
            ],
            DocumentName='AWS-RunShellScript',
            TimeoutSeconds=240,

            Parameters={
                'commands':OSLevelCommands,
                'executionTimeout':['3600'],
                'workingDirectory':['/tmp']
            },
            OutputS3BucketName=BUCKET_NAME,
            OutputS3KeyPrefix=RUNIDPREFIX+'ssm-output-file',
            ServiceRoleArn='arn:aws:iam::' + ACCOUNT_ID + ':role/' + SSMIAMRoleForSNS,
            NotificationConfig={
                'NotificationArn': SNS_TOPIC,
                'NotificationEvents': [
                    'Success', 'TimedOut', 'Cancelled', 'Failed',
                ],
                'NotificationType': 'Invocation',
            }
        )
    except ValueError as e:
        message = "Executing SSM Run command failed on instance " + instance_id + str(e['ErrorMessage'])

    # Polling SSM for completion of commands execution. We will wait for 60 seconds then move on
    count = 0
    maxcount = 20
    while (count < maxcount):
        status = (ssm.list_commands(CommandId=response['Command']['CommandId']))['Commands'][0]['Status']
        print("Waiting for SSM to return Success (" + str(count) + " of " + str(maxcount) + " retries) -- SSM status is: " + status)
        if status == 'Pending' or status == 'InProgress':
            time.sleep(3)
            count += 1
        else:
            break
    #Allow SSM_DRAIN_TIME seconds for SSM to complete commands after a "Success" status has processed
    if status == 'Success':
        message = "Successfully sent SSM Run Command to instance " + instance_id

        print("Waiting " + str(SSM_DRAIN_TIME) + " Seconds for SSM to complete uploads.")
        time.sleep(SSM_DRAIN_TIME)
    elif status == 'InProgress':
        message = "SSM Run Command was queued, but failed to execute before timeout! OS level commands were _NOT_ performed."

    print(message)
    if SNS_TOPIC:
        send_sns_message(message)

#remove an EC2 instance profile if it is attached, otherwise just continue on
#Note that this is running under the assumption at writing that only one instance profile can be attached at a time
def remove_EC2_IAM_role(ec2Client, instance_id):
    try:
        thisIAMAssociationIDInfo = ec2Client.describe_iam_instance_profile_associations(Filters=[{'Name': 'instance-id', 'Values': [instance_id]}])

        if len(thisIAMAssociationIDInfo['IamInstanceProfileAssociations']) == 0:
            message = 'No IAM instance profile attached to instance ' + instance_id
        else:
            thisIAMAssociationID = thisIAMAssociationIDInfo['IamInstanceProfileAssociations'][0]['AssociationId']
            ec2Client.disassociate_iam_instance_profile(AssociationId=thisIAMAssociationID)
            message = 'Successful IAM role removal for ' + instance_id
    except ValueError as e:
        message = "Unable to remove IAM role correctly --  " + instance_id + str(e['ErrorMessage'])

    print(message)

def attach_EC2_SSM_execution_IAM_role(ec2Client, instance_id):
    try:
        ec2Client.associate_iam_instance_profile(InstanceId=instance_id, IamInstanceProfile={'Arn': SSMEC2IAMPROFILE , 'Name': 'SecurityResponseEC2InstanceRoleProfile'})
        message = "IAM instance profile successfully attached --  " + instance_id
    except ValueError as e:
        message = "Unable to attach IAM role correctly --  " + instance_id + str(e['ErrorMessage'])
    print(message)



if __name__ == "__main__":

    ACCOUNT_ID = boto3.client('sts').get_caller_identity().get('Account')

    # Define Argument Parser
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--iid', required=True, help='instance id')
    parser.add_argument('-g', '--sgid', required=True, help='security group id')
    parser.add_argument('-r', '--region', required=False, help='region')
    parser.add_argument('-b', '--bucket', required=False, help='bucket')
    parser.add_argument('-t', '--topic', required=False, help='topic')

    args = parser.parse_args()

    AREGION = 'us-west-2'
    if args.region:
        AREGION=args.region


    instance_id = args.iid
    instanceid_is_valid(instance_id)

    ec2Client = boto3.client('ec2', region_name=AREGION)
    asgClient = boto3.client('autoscaling', region_name=AREGION)
    ssmClient = boto3.client('ssm', region_name=AREGION)

    BUCKET_NAME = "login-gov.quarantine-ec2."+ACCOUNT_ID+"-"+AREGION
    if args.bucket:
        BUCKET_NAME = args.bucket

    SNS_TOPIC = "arn:aws:sns:"+AREGION+":"+ACCOUNT_ID+":slack-events"
    if args.topic:
        SNS_TOPIC = args.topic

    console_screenshot(ec2Client, instance_id)

    snapshot(ec2Client, instance_id)

    try:
        set_termination_protection(ec2Client, instance_id)
    except:
        pass

    isolateSG = args.sgid
    #print(isolateSG)
    if not isolateSG:
        #findSG
        """group_name = '*-quarantine'
        response = ec2Client.describe_security_groups(
            Filters=[
                dict(Name='tag:description', Values=[group_name])
            ]
        )
        try:
            isolateSG = response['SecurityGroups'][0]['GroupId']
        except:
            pass
        if not isolateSG:
            isolateSG = create_isolate_sg(ec2Client, VPC_ID, instance_id)"""
        isolateSG = create_isolate_sg(ec2Client, VPC_ID, instance_id)
    
    print(isolateSG)
    isolate_instance(ec2Client, instance_id, VPC_ID, isolateSG)

    set_tags(ec2Client, instance_id)

    message = 'Security Response mechanism complete for instance: ' + instance_id
    print(message)