#!/bin/bash

set -euo pipefail

# Deal with Arguments
while getopts e:c: opt
do
  case $opt in
    c) CERT_ENV="${OPTARG}" ;;
    e) ENV="${OPTARG}"      ;;
   \?) exit 1               ;;
  esac
done
shift $((OPTIND-1))

if [[ -z "${ENV:-}" ]]; then
  echo "Must specify ENVIRONMENT (-e)" >&2
  exit 1
fi

if [[ -z "${CERT_ENV:-}" ]]; then
  CERT_ENV=$ENV
fi

# Set AWS Account/Region
PROD_ENVIRONMENTS=("prod" "staging" "dm")
AWS_ACCOUNT_NUM=""

if [[ " ${PROD_ENVIRONMENTS[@]} " =~ " ${ENV} " ]]; then
  AWS_ACCOUNT_NUM="555546682965"  
else
  AWS_ACCOUNT_NUM="894947205914"
fi

# Setup DB
rbenv exec bundle exec rake db:create db:migrate:monitor_concurrent --trace

# Set Proxy Variables
export http_proxy="http://obproxy.login.gov.internal:3128"
export https_proxy="http://obproxy.login.gov.internal:3128"
export no_proxy="localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,lambda.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,sns.us-west-2.amazonaws.com,sqs.us-west-2.amazonaws.com,events.us-west-2.amazonaws.com,metadata.google.internal,sts.us-west-2.amazonaws.com"

# Configure pivcac.conf
#cd /srv/pki-rails/current/public
#RUBY_DIR=`rbenv which ruby`; sed -i "s~<RUBY_VERSION_PLACEHOLDER>~${RUBY_DIR};~g" /opt/nginx/conf/sites.d/pivcac.conf

# Fetch DHParam from AWS
#aws s3 cp s3://login-gov.secrets.${AWS_ACCOUNT_NUM}-us-west-2/${ENV}/dhparam /etc/ssl/certs/dhparam.pem

# Fetch LetsEncrypt bundle from AWS
aws s3 cp s3://login-gov-pivcac-${ENV}.${AWS_ACCOUNT_NUM}-us-west-2/letsencrypt.${CERT_ENV}.tar.gz /root/letsencrypt.${CERT_ENV}.tar.gz > /dev/null 2>&1 || echo 'LetsEncrypt bundle does not exist in S3'

# Set Cron Jobs
echo "@daily root flock -n /tmp/update_letsencrypt_certs.lock -c \"/usr/local/bin/update_letsencrypt_certs -e ${ENV} -c ${CERT_ENV}\" " > /etc/cron.d/update_letsencrypt_certs
chown root: /etc/cron.d/update_letsencrypt_certs
chmod 700 /etc/cron.d/update_letsencrypt_certs

# Set nginx pivcac.conf environment
#sed -i "s~<ENVIRONMENT>~${CERT_ENV}~g" /opt/nginx/conf/sites.d/pivcac.conf

# Check if bundle exists/is not null
cd /etc
[ -s /root/letsencrypt.${CERT_ENV}.tar.gz ] && tar zxf /root/letsencrypt.${CERT_ENV}.tar.gz || certbot certonly --agree-tos -n --dns-route53 -d *.pivcac.${CERT_ENV}.identitysandbox.gov --email identity-devops@login.gov --server https://acme-v02.api.letsencrypt.org/directory --deploy-hook "/usr/local/bin/push_letsencrypt_certs.sh -e ${ENV} -c ${CERT_ENV}" --preferred-chain 'ISRG Root X1'  --key-type rsa --rsa-key-size 2048

certbot renew -n --deploy-hook "/usr/local/bin/push_letsencrypt_certs.sh -e ${ENV} -c ${CERT_ENV}" --preferred-chain 'ISRG Root X1' --key-type rsa --rsa-key-size 2048

# Start Passenger
bundle exec puma -b ssl://0.0.0.0:3001?key=/app/keys/localhost.key&cert=/app/keys/localhost.crt

# Keep Pod Running
#tail -f /dev/null
