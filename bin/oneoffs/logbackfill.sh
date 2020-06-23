#!/bin/sh
#
# This sets up a logtstash process on an elk host that will slurp in cloudtrail
# data from a specified time in the past until today into a special index that
# we can search.
#

usage() {
	echo
	echo "usage:  $0 <indexname> <daysago>"
	echo "  indexname is the index to send the cloudtrail data into"
	echo "  daysago is how many days back to go"
	echo
	echo "example:  $0 importedcloudtrail-2020-06-19-90days 90"
	echo
	echo "this script must be run on an elk system that has a working cloudtrail logstash"
	echo "going so that it can copy it's config."
	exit 1
}

if [ "$1" = "-d" ] ; then
	echo "stopping backfill import"
	sv stop /etc/service/backfilllogstash
	rm -rf /etc/service/backfilllogstash /etc/logstash/backfilllogstashconf.d /usr/share/logstash/data_backfilllogstash /usr/share/logstash/.sincedb_backfilllogstash /etc/cron.d/logbackfill  /etc/sv/backfilllogstash
	exit 0
fi

if [ -z "$2" -o -z "$1" ] ; then
	echo "Error:  missing arguments"
	usage
fi

if [ ! -d  /etc/logstash/cloudtraillogstashconf.d ] ; then
	echo "Error:  missing /etc/logstash/cloudtraillogstashconf.d config dir"
	usage
fi

# create sincedb
mkdir -p /usr/share/logstash/data_backfilllogstash
chown logstash /usr/share/logstash/data_backfilllogstash
date --date="$2 days ago" "+%F 00:00:00 +0000" > /usr/share/logstash/.sincedb_backfilllogstash


# create config files from the previous cloudtrail config files
mkdir -p /etc/logstash/backfilllogstashconf.d /srv/tmp/backfilllogstash /var/log/backfilllogstash
chmod 700 /srv/tmp/backfilllogstash
chown logstash /srv/tmp/backfilllogstash
cp -rp /etc/logstash/cloudtraillogstashconf.d/* /etc/logstash/backfilllogstashconf.d/
rm -f /etc/logstash/backfilllogstashconf.d/30-s3output.conf /etc/logstash/backfilllogstashconf.d/70-elblogsin.conf
sed -i "s/index => \"logstash-cloudtrail-.*\"/index => \"$1\"/" /etc/logstash/backfilllogstashconf.d/30-ESoutput.conf
sed -i "s/sincedb_cloudtraillogstash/sincedb_backfilllogstash/g" /etc/logstash/backfilllogstashconf.d/30-cloudtrailin.conf

mkdir -p /etc/sv/backfilllogstash/log
ln -s /etc/sv/backfilllogstash/ /etc/service/backfilllogstash
sed 's/cloudtraillogstash/backfilllogstash/g' /etc/sv/cloudtraillogstash/run > /etc/service/backfilllogstash/run
sed 's/cloudtraillogstash/backfilllogstash/g' /etc/sv/cloudtraillogstash/log/run > /etc/service/backfilllogstash/log/run
chmod +x  /etc/service/backfilllogstash/run  /etc/service/backfilllogstash/log/run


# launch logstash with config
sleep 6
sv start /etc/service/backfilllogstash


# stop it when it's up to now
cp "$0" /root/logbackfill_donotdelete.sh
chmod +x /root/logbackfill_donotdelete.sh
cat <<EOF > /etc/cron.d/logbackfill
# stop the backfill logstash once it is up to $(date +%F)
0 23 * * * root if grep $(date +%F) /usr/share/logstash/.sincedb_backfilllogstash ; then /root/logbackfill_donotdelete.sh -d ; fi
EOF
