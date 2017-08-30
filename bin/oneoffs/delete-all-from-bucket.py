#!/usr/bin/env python

# https://stackoverflow.com/a/35306665

import click
import boto3

@click.command()
@click.argument('bucket')
def delete_all_versions(bucket):
    """Deletes all versions of all objects from the given bucket"""
    if raw_input("This will delete all the contents of the %s bucket.  Are you sure? (y/n): " % bucket) != "y":
        return
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(bucket)
    bucket.object_versions.delete()

if __name__ == '__main__':
    delete_all_versions()
