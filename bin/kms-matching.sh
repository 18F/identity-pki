#!/bin/sh
#
# This script searches the KMS logging data from DynamoDB and CloudWatch
# for decryption events for a given user id
# all times are in utc
#
# Aspirations:
# Format results

usage () {
cat >&2 << EOM

usage:  ./kms-matching.sh --uuid <uuid> --context <context> --hours <hours> --env <environment> [--nologs]
  uuid is the user id from the notification
  context is either password-digest or pii-encryption defaults to password-digest
  hours is the numbers to search from the current time defaults to 24
  environment is the environment name to search default is prod
  nologs skips the option to query CloudWatch Logs for further analysis

  examples:  ./kms-matching.sh -uuid 38d96999-9999-9999-9999-888888888888
             searches for the uuid provided with password-digest as the context for 24 hours in prod logs
			
             ./kms-matching.sh --uuid 38d96999-9999-9999-9999-888888888888 --context password-digest
             ./kms-matching.sh --uuid 38d96999-9999-9999-9999-888888888888 --context password-digest --hours 36
             ./kms-matching.sh --uuid 38d96999-9999-9999-9999-888888888888 --context password-digest --hours 36 --env staging
EOM
exit 1
}

# default values
context='password-digest'
hours='24H'
env='prod'
nologs=0

if [[ "$#" -eq 0 ]]; then
	echo "Error:  missing arguments"
	usage
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --uuid) uuid="$2"; shift ;;
		--context) context="$2"; shift ;;
		--hours) hours="$2H"; shift ;;
		--env) env="$2"; shift;;
        --nologs) nologs=1; shift;;
        *) echo "Unknown argument passed: $1"; usage ;;
    esac
    shift
done

if [[ ! -n "${uuid// /}" ]]; then
	echo "Must provide a value for uuid"
	usage
fi

set -eu pipefail

key=$(printf "\"%s-%s\"" "$uuid" "$context")

echo "Searching for $key"

# date time for CloudWatch query
epoch_start=`date -v-$hours "+%s"`
epoch_end=`date "+%s"`

start_time=`date -u -v-$hours "+%Y-%m-%dT%H:%M:%SZ"`
end_time=`date -u "+%Y-%m-%dT%H:%M:%SZ"`

start_time=$(printf "\"%s\"" "$start_time")
end_time=$(printf "\"%s\"" "$end_time")

echo "Query datetime between $start_time and $end_time"

echo "DDB Table Query Results"
aws dynamodb query \
--table-name $env-kms-logging \
--key-condition-expression "#U = :uuid_context AND #TS BETWEEN :st AND :et" \
--expression-attribute-values "{\":uuid_context\":{\"S\":$key}, \":st\":{\"S\":$start_time}, \":et\":{\"S\":$end_time}}" \
--expression-attribute-names '{"#U":"UUID", "#TS":"Timestamp"}' \
--projection-expression "#U, #TS, Correlated" \
--output text

if [[ $nologs == 1 ]]
then
  exit 0
fi

read -p "Do you need to review the CloudWatch Logs? " -n 1 -r
echo   
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 0
fi

echo
echo "CW Logs Query Results"

query_id=$(aws logs start-query --log-group-name $env'_/srv/idp/shared/log/kms.log' \
--start-time $epoch_start \
--end-time $epoch_end \
--query-string "fields @timestamp | \
sort @timestamp asc | \
parse @message '\"user_uuid\":\"*\"' as uuid | \
parse @message '\"action\":\"*\"' as action | \
parse @message '\"context\":\"*\"' as context | \
filter uuid = '$uuid' and action = 'decrypt' and context = '$context'" \
--output text)

echo "CW Query ID $query_id"
echo "Waiting for results"

# CW Insights query runs async
# Need to check status
query_status=$(aws logs get-query-results --query-id $query_id --query [status] --output text)

while [ "$query_status" = "Running" ]; do
	sleep 15
	query_status=$(aws logs get-query-results --query-id $query_id --query [status] --output text)
done

aws logs get-query-results --query-id $query_id --output text

echo "Completed"
