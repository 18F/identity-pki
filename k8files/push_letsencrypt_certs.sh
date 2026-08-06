#!/bin/bash
#
# Push letsencrypt certs to S3 and reload certs in nginx
# Usually called by certbot when a new cert is received
#
set -eu

while getopts e:c: opt
do
  case $opt in
    e) ENV="${OPTARG}"      ;;
   \?) exit 1               ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${ENV:-}" ]; then
  echo "Must specify ENVIRONMENT (-e)" >&2
  exit 1
fi

# Set AWS Account/Region
PROD_ENVIRONMENTS=("prod" "staging" "dm")
AWS_ACCOUNT_NUM=""

if [[ " ${PROD_ENVIRONMENTS[*]} " =~ " ${ENV} " ]]; then
  AWS_ACCOUNT_NUM="555546682965"
else
  AWS_ACCOUNT_NUM="894947205914"
fi

if [ -e /root/letsencrypt.${ENV}.tar.gz ]; then
  rm /root/letsencrypt.${ENV}.tar.gz
fi

cd /etc
tar czvf /root/letsencrypt.${ENV}.tar.gz letsencrypt
if [ -e /root/letsencrypt.${ENV}.tar.gz ]; then
  echo "run push"
  aws s3 cp /root/letsencrypt.${ENV}.tar.gz s3://login-gov-pivcac-${ENV}.${AWS_ACCOUNT_NUM}-us-west-2/
else
  echo ERROR: Failed to create cert bundle /root/letsencrypt.${ENV}.tar.gz 1>&2
  exit 1
fi

if [ -e /app/tmp/pids/puma.state ]; then
  echo "restart puma
  bundle exec pumactl --state /app/tmp/pids/puma.state restart
fi
