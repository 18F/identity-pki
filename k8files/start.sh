#!/bin/sh

# start up crond so that it can update the CRLs periodically
/usr/sbin/cron

# Start the pivcac app up!
exec bundle exec rackup config.ru --host ssl://0.0.0.0:3000?key=/app/keys/localhost.key&cert=/app/keys/localhost.crt

