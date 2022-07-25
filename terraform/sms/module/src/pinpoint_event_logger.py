# pinpoint_event_logger - Read PinPoint events from Kinesis and log them to
# STDOUT, which lands as well formed JSON in CloudWatch Logs

import json
import base64

def lambda_handler(event, context):
    for record in event['Records']:
        # Kinesis data is base64 encoded so decode here
        payload = json.loads(base64.b64decode(record["kinesis"]["data"]))

        if 'destination_phone_number' in payload['attributes']:
            n = payload['attributes']['destination_phone_number']

            # Mask half the string preserving enough information to be
            # useful in troubleshooting while preserving privacy
            n = n[:int(len(n) / 2)].ljust(len(n), '*')

            payload['attributes']['destination_phone_number'] = n

        print(json.dumps(payload))

