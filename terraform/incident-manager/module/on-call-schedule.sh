#!/bin/bash

set -euo pipefail

ROTATION=$(aws ssm-contacts list-rotations --query "Rotations[?Name=='$2']")
CONTACT_EXISTS=$(aws ssm-contacts list-contacts --alias-prefix "$1" \
                 --type "ONCALL_SCHEDULE" | jq '.Contacts | length')

if [[ $(echo "$ROTATION" | jq 'length' ) -gt 0 ]]; then
  if [[ $CONTACT_EXISTS -eq 0 ]]; then
    aws ssm-contacts create-contact \
      --alias "$1" \
      --display-name "$2" \
      --type ONCALL_SCHEDULE \
      --plan "{\"RotationIds\": [$(echo "$ROTATION" | jq '.[].RotationArn' )]}" \
      --output text
  fi
fi


