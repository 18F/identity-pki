#!/bin/sh

usage() {
	echo
	echo "usage:  $0 <cloudtrailbucketname> <indexname> <daysago>"
	echo "  cloudtrailbucketname is the name of the cloudtrail s3 bucket to slurp from"
	echo "  indexname is the index to send the data into"
	echo "  daysago is how many days back to go"
	echo
	echo "example:  $0 s3://cloudtrailbucket/AWSLogs/foo/bar/2020/ importedcloudtrail-2020-06-19-90days 90"
	echo
	echo "this script must be run on a system that has a working cloudtrail logstash"
	echo "going so that it can copy it's config."
	exit 1
}

if [ "$1" = "-d" ] ; then
	echo "stopping backfill import"
	sv stop /etc/service/backfilllogstash
	rm -rf /etc/service/backfilllogstash /etc/logstash/backfilllogstashconf.d /usr/share/logstash/data_backfilllogstash /usr/share/logstash/.sincedb_backfilllogstash /etc/cron.d/logbackfill
	exit 0
fi

if [ -z "$3" -o -z "$2" -o -z "$1" ] ; then
	echo "Error:  missing arguments"
	usage
fi

if [ ! -d  /etc/logstash/cloudtraillogstashconf.d ] ; then
	echo "Error:  missing /etc/logstash/cloudtraillogstashconf.d config dir"
	usage
fi

# create sincedb
mkdir -p /usr/share/logstash/data_backfilllogstash
date --date='90 days ago' "+%F 00:00:00 +0000" > /usr/share/logstash/.sincedb_backfilllogstash


# create config files
mkdir -p /etc/logstash/backfilllogstashconf.d
cp -rp /etc/logstash/cloudtraillogstashconf.d/* /etc/logstash/backfilllogstashconf.d/
rm  /etc/logstash/backfilllogstashconf.d/30-s3output.conf
sed -i "s/index => \"logstash-cloudtrail-.*\"/index => \"$2\"/" /etc/logstash/backfilllogstashconf.d/30-ESoutput.conf

cp -rp /etc/service/cloudtraillogstash /etc/service/backfilllogstash
sed -i 's/cloudtraillogstash/backfilllogstash/g' /etc/service/backfilllogstash/run


# launch logstash with config
sv restart /etc/service/backfilllogstash

# stop it when it's up to now
cp "$0" /root/logbackfill_donotdelete.sh
chmod +x /root/logbackfill_donotdelete.sh
cat <<EOF > /etc/cron.d/logbackfill
# stop the backfill logstash once it is up to $(date +%F)
0 23 * * * root if grep $(date +%F) /usr/share/logstash/.sincedb_backfilllogstash ; then /root/logbackfill_donotdelete.sh -d ; fi
EOF
