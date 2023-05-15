#!/bin/sh
#
# Push letsencrypt certs to S3 and reload certs in nginx
# Usually called by certbot when a new cert is received
#
set -eu

if [ -e /root/letsencrypt.reviewapp.tar.gz ]; then
  rm /root/letsencrypt.reviewapp.tar.gz
fi

cd /etc
tar czvf /root/letsencrypt.reviewapp.tar.gz letsencrypt
if [ -e /root/letsencrypt.reviewapp.tar.gz ]; then
  aws s3 cp /root/letsencrypt.reviewapp.tar.gz s3://login-gov-pivcac-reviewapp.894947205914-us-west-2/
else
  echo ERROR: Failed to create cert bundle /root/letsencrypt.reviewapp.tar.gz 1>&2
  exit 1
fi

service passenger force-reload
