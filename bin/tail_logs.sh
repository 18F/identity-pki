#!/bin/sh
#
# This script tails log files on the IdP application servers
# to aid in debugging.

chef_env=$1
username=$TF_VAR_chef_id

usage() {
  echo "usage:  $0 <chef_env>"
  echo "example:  $0 qa"
}

if [ -z "$chef_env" ] ; then
  usage
  exit 1
fi
if [ -z "$username" ] ; then
  echo "ERROR: MUST SET TF_VAR_chef_id to your Chef username"
  echo "example: export TF_VAR_chef_id=jdoe"
  exit 1
fi

bastion_host="$username@jumphost.$chef_env.login.gov"

echo "Connecting to $chef_env via $bastion_host..."
sleep 1

ssh -n -o ProxyCommand="ssh -A $bastion_host -W %h:%p" ubuntu@idp1-0 "sudo tail -f /var/log/passenger/error.log /srv/idp/current/log/*.log" & 
ssh -n -o ProxyCommand="ssh -A $bastion_host -W %h:%p" ubuntu@idp2-0 "sudo tail -f /var/log/passenger/error.log /srv/idp/current/log/*.log" & 
ssh -n -o ProxyCommand="ssh -A $bastion_host -W %h:%p" ubuntu@worker "sudo tail -f /var/log/passenger/error.log /srv/idp/current/log/*.log"