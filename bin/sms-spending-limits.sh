#!/bin/sh
#
# This script reports on the status of the spending limits in our two regions
#

aws pinpoint-sms-voice-v2 describe-spend-limits --region us-west-2 > /tmp/west.$$
aws pinpoint-sms-voice-v2 describe-spend-limits --region us-east-1 > /tmp/east.$$
diff -c /tmp/west.$$ /tmp/east.$$ > /tmp/diff.$$

if [ -s /tmp/diff.$$ ] ; then
	echo "###################################################################"
	echo
	echo "spending limits differ between us-west-2 and us-east-1!"
	echo
	cat /tmp/diff.$$
	echo
	echo "please make these the same!"
	echo
fi

LIMIT=$(cat /tmp/west.$$ | jq '.SpendLimits[] | select(.Name == "TEXT_MESSAGE_MONTHLY_SPEND_LIMIT") | .EnforcedLimit')
MAX=$(cat /tmp/west.$$ | jq '.SpendLimits[] | select(.Name == "TEXT_MESSAGE_MONTHLY_SPEND_LIMIT") | .MaxLimit')
EASTLIMIT=$(cat /tmp/east.$$ | jq '.SpendLimits[] | select(.Name == "TEXT_MESSAGE_MONTHLY_SPEND_LIMIT") | .EnforcedLimit')
EASTMAX=$(cat /tmp/east.$$ | jq '.SpendLimits[] | select(.Name == "TEXT_MESSAGE_MONTHLY_SPEND_LIMIT") | .MaxLimit')

echo "us-west-2 SMS spending limit: $LIMIT"
echo "us-west-2 max spending limit: $MAX"
echo "us-east-1 SMS spending limit: $EASTLIMIT"
echo "us-east-1 max spending limit: $EASTMAX"

rm -f /tmp/west.$$ /tmp/east.$$ /tmp/diff.$$

