import boto3
import json
from datetime import datetime, timedelta

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    ami_deleted_days = int(event['ami_deleted_days'])
    ami_deprecated_days = int(event['ami_deprecated_days'])
    dry_run = bool(event['dry_run'])
    dtnow = datetime.utcnow()
    ec2 = boto3.client('ec2')

    all_images = ec2.describe_images(
        Owners=[
            'self',
        ],
        Filters=[
            {
                'Name': 'state',
                'Values': [
                    'available',
                ]
            },
        ]
    )['Images']

    for image in all_images:
        created_at = datetime.strptime(image['CreationDate'][:-1], "%Y-%m-%dT%H:%M:%S.%f")

        if created_at < dtnow - timedelta(ami_deleted_days):
            print('Deregistering {} ({})'.format(image['ImageLocation'],
                                                image['ImageId']))
            if not dry_run:
                ec2.deregister_image(ImageId=image['ImageId'])

            for block in image['BlockDeviceMappings']:
                if "Ebs" in block:
                    if not dry_run:
                        print('Deleted Snapshot {}'.format(block["Ebs"]["SnapshotId"]))
                    ec2.delete_snapshot(SnapshotId=block["Ebs"]["SnapshotId"])

        elif created_at < dtnow - timedelta(ami_deprecated_days):
            if 'DeprecationTime' not in image:
                print('Deprecating {} ({})'.format(image['ImageLocation'],
                                                    image['ImageId']))

                if not dry_run:
                    ec2.enable_image_deprecation(ImageId=image['ImageId'], DeprecateAt=dtnow)

