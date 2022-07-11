# This is required to get boto3 (v1.24.21) which provides access to the
# lastLaunchedTime attribute of images. Once the default runtime of lamda boto3
# library exceeds v1.24.21 this can be safely removed.

import sys
from pip._internal import main

main([
    'install', '-I', '-q', 'boto3', '--target', '/tmp/', '--no-cache-dir',
    '--disable-pip-version-check'
])
sys.path.insert(0, '/tmp')

# End of previous comment

import boto3
import json
from datetime import datetime, timedelta


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    unassociated_expiration_days = int(event['expireUnassociatedinDays'])
    associated_expiration_days = int(event['expireAssociatedinDays'])
    dry_run = bool(event['dryRun'])

    dtnow = datetime.utcnow()
    ec2 = boto3.client('ec2')

    all_images = ec2.describe_images(Owners=[
        'self',
    ])['Images']

    all_instances = ec2.describe_instances()

    images_in_use = set()

    for r in all_instances['Reservations']:
        for instance in r['Instances']:
            images_in_use.add(instance['ImageId'])

    for image in all_images:
        if image['ImageId'] in images_in_use:
            continue
        created_at = datetime.strptime(image['CreationDate'][:-1],
                                       "%Y-%m-%dT%H:%M:%S.%f")

        if created_at > dtnow - timedelta(unassociated_expiration_days):
            continue

        response = ec2.describe_image_attribute(Attribute='lastLaunchedTime',
                                                ImageId=image['ImageId'])

        try:
            lastLaunchedValue = response['LastLaunchedTime']['Value']
        except KeyError:
            lastLaunchedValue = ''

        if lastLaunchedValue != '':
            lastLaunched = datetime.strptime(lastLaunchedValue[:-1],
                                             "%Y-%m-%dT%H:%M:%S")

            if lastLaunched < dtnow - timedelta(associated_expiration_days):
                deregister_image_and_snapshots(image, dry_run)

        elif created_at < dtnow - timedelta(unassociated_expiration_days):
            deregister_image_and_snapshots(image, dry_run)


def deregister_image_and_snapshots(image, dry_run):
    ec2 = boto3.client('ec2')

    print('Deregistering {} ({})'.format(image['ImageLocation'],
                                         image['ImageId']))

    if not dry_run:
        ec2.deregister_image(ImageId=image['ImageId'])

    for block in image['BlockDeviceMappings']:
        if "Ebs" in block:
            print('Deleted Snapshot {}'.format(block["Ebs"]["SnapshotId"]))

            if not dry_run:
                ec2.delete_snapshot(SnapshotId=block["Ebs"]["SnapshotId"])
