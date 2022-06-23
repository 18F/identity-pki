import json
import boto3
from datetime import datetime, timedelta


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    unassociated_expiration_days = int(event['expireUnassociatedinDays'])
    associated_expiration_days = int(event['expireAssociatedinDays'])
    dry_run = bool(event['dryRun'])

    dtnow = datetime.utcnow()
    ec2 = boto3.client('ec2')

    all_images = ec2.images.filter(Owners=['self'])

    images_in_use = {instance.image_id for instance in ec2.instances.all()}

    for image in all_images:
        if image.id in images_in_use:
            continue
        created_at = datetime.strptime(image.creation_date,
                                       "%Y-%m-%dT%H:%M:%S%Z")

        if created_at > dtnow - timedelta(unassociated_expiration_days):
            continue

        if image.lastLaunchedTime != '':
            lastLaunched = datetime.strptime(image.lastLaunchedTime,
                                             "%Y-%m-%dT%H:%M:%S%Z")

            if lastLaunched < dtnow - timedelta(associated_expiration_days):
                deregister_image_and_snapshots(image, dry_run)

        elif created_at < dtnow - timedelta(unassociated_expiration_days):
            deregister_image_and_snapshots(image, dry_run)


def deregister_image_and_snapshots(image, dry_run):
    ec2 = boto3.client('ec2')

    print('Deregistering {} ({})'.format(image.name, image.id))

    if not dry_run:
        ec2.deregister_image(ImageId=image.id)

    for block in image.block_device_mapping:
        if "ebs" in block:
            print('Deleted Snapshot {}'.format(block.ebs.snapshot_id))

            if not dry_run:
                ec2.delete_snapshot(block.ebs.snapshot_id)
