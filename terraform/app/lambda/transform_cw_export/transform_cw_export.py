import gzip
import io
import json
import logging
import os
import csv
from datetime import datetime
import uuid
from hashlib import sha1

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def convert_to_csv(s3_client, bucket, key, destination_key, json_encoded):
    logger.info(
        f"Converting raw file '{bucket}/{key}' to csv at '{bucket}/{destination_key}'"
    )
    with io.BytesIO() as downloaded_memory_file:
        s3_client.download_fileobj(bucket, key, downloaded_memory_file)
        downloaded_memory_file.seek(0)

        with io.BytesIO() as upload_memory_file:
            with io.TextIOWrapper(
                buffer=upload_memory_file, encoding="utf-8"
            ) as file_wrapper:
                csv_writer = csv.writer(file_wrapper, delimiter=",")
                csv_writer.writerow(["cloudwatch_timestamp", "message"])

                with gzip.open(
                    downloaded_memory_file,
                    mode="rt",
                    encoding="utf-8",
                ) as gz_file:

                    for line in gz_file.readlines():
                        original_line = str(line)
                        timestamp = original_line[:24]
                        message = original_line[25:].rstrip()

                        if not json_encoded or message.startswith('{"'):
                            message = enforce_unique_identifier(message, key)
                            csv_writer.writerow([timestamp, message])

                file_wrapper.seek(0)
                s3_client.upload_fileobj(upload_memory_file, bucket, destination_key)


def should_json_encode(log_groups, log_group_name):
    for log_group in log_groups:
        if log_group["name"] == log_group_name and log_group["json_encoded"]:
            return True
    return False


def get_unique_id_name(key: str) -> str:
    log_group_name = key.split("/")[1].split("_")[-1]
    if "events.log" == log_group_name:
        unique_id_name = "id"
    elif "production.log" == log_group_name:
        unique_id_name = "uuid"
    else:
        raise ValueError(f"Unrecognized log group name: {log_group_name}")
    return unique_id_name


def uuid5(name):
    if isinstance(name, str):
        name = bytes(name, "utf-8")
    hash = sha1(name).digest()
    return uuid.UUID(bytes=hash[:16], version=5)


def enforce_unique_identifier(message: str, original_key: str):
    unique_id_name = get_unique_id_name(original_key)
    try:
        message_dict = json.loads(message)
    except json.JSONDecodeError:
        logger.warning(
            f"Could not enforce unique identifier due to invalid JSON format: {message}"
        )
        return message
    if not unique_id_name in message_dict:
        message_dict[unique_id_name] = str(uuid5(message))
    message = json.dumps(message_dict, separators=(",", ":"))
    return message


def lambda_handler(event, context):
    records = event.get("Records")
    logs = boto3.client("logs")
    s3 = boto3.client("s3")

    if "LOG_GROUPS" not in os.environ:
        raise Exception("LOG_GROUPS not defined")

    log_groups = json.loads(os.environ["LOG_GROUPS"])

    # Since this lambda function is triggered per S3 upload, length of records is expected to be 1
    assert len(records) == 1

    entry = records.pop()
    s3_data = entry.get("s3", {})
    bucket = s3_data["bucket"]["name"]
    original_key = s3_data["object"]["key"]
    original_key_array = original_key.split("/")

    logsdir, underscore_log_group_name, _id, log_stream_prefix, filename = (
        original_key_array
    )

    log_group_name = underscore_log_group_name.replace("_", "/").replace("/", "_", 1)
    prefix = "/".join([logsdir, underscore_log_group_name])
    in_filename = ".".join([log_stream_prefix, filename])
    out_filename = in_filename.replace("/", ".").replace(".gz", ".csv")

    log_stream_details = logs.describe_log_streams(
        logGroupName=log_group_name,
        logStreamNamePrefix=log_stream_prefix,
    )

    create_time_in_ms = log_stream_details["logStreams"][0]["creationTime"]
    create_day = datetime.fromtimestamp(create_time_in_ms / 1000).strftime("%Y/%m/%d")

    destination_key = f"{prefix}/processed/{create_day}/{out_filename}"

    convert_to_csv(
        s3,
        bucket,
        original_key,
        destination_key,
        json_encoded=should_json_encode(log_groups, log_group_name),
    )

    logger.info(f"Deleting: '{bucket}/{original_key}'")
    s3.delete_object(Bucket=bucket, Key=original_key)
