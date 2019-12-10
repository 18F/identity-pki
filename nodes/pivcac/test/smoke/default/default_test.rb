# # encoding: utf-8

# Inspec tests for proxy node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('websrv') do
  it { should exist }
end
  
describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

renewal_config = file("/etc/letsencrypt/renewal/pivcac.ci.identitysandbox.gov.conf")
describe renewal_config do
  it { should exist }
  it { should be_file }
  # Make sure we aren't DOSing letsencrypt from CI.
  its('content') { should match (/acme-staging/) }
end

# check that passenger is installed and running
describe service('passenger') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/srv/pki-rails/current/config/application.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  it { should_not be_readable.by('others') }
  it { should be_readable.by_user('websrv') }
  its('content') { should include('production:') }
  its('content') { should include('secret_key_base') }
end

# Ensure we compiled passenger/nginx with the right OpenSSL.
# This test will break when you upgrade our OpenSSL. Sorry.
describe command('/opt/nginx/sbin/nginx -V') do
  its('exit_status') { should eq 0 }
  its('stderr') { should match (/built with OpenSSL 1.0.2t/) }
end

# Ensure our nginx configuration is a valid one.
describe command('/opt/nginx/sbin/nginx -t') do
  its('exit_status') { should eq 0 }
end

describe file('/usr/local/bin/update_cert_revocations') do
  it { should exist }
  it { should be_executable }
end

describe file('/usr/local/bin/update_letsencrypt_certs') do
  it { should exist }
  it { should be_executable }
end

describe port(443) do
  it { should be_listening }
end


# filebeat is harvesting common logs
describe command("grep 'Harvester started for file' /var/log/filebeat/filebea* | awk '{print $NF}' | sort | uniq") do
  its('stdout') { should include '/var/log/alternatives.log' }
  its('stdout') { should include '/var/log/amazon/ssm/amazon-ssm-agent.log' }
  its('stdout') { should include '/var/log/amazon/ssm/errors.log' }
  its('stdout') { should include '/var/log/amazon/ssm/hibernate.log' }
  its('stdout') { should include '/var/log/apport.log' }
  its('stdout') { should include '/var/log/apt/history.log' }
  its('stdout') { should include '/var/log/apt/term.log' }
  its('stdout') { should include '/var/log/audit/audit.log' }
  its('stdout') { should include '/var/log/auth.log' }
# TODO: add once we either test the awsagent update process or the build of this instance takes long
# enough for the awsagent update to occur automatically.
#  its('stdout') { should include '/var/log/awsagent-update.log' }
  its('stdout') { should include '/var/log/awslogs-agent-setup.log' }
  its('stdout') { should include '/var/log/awslogs.log' }
  its('stdout') { should include '/var/log/clamav/clamav.log' }
# TODO: add once we have a test that updates the clamav definitions.
  its('stdout') { should include '/var/log/clamav/freshclam.log' }
  its('stdout') { should include '/var/log/cloud-init-output.log' }
  its('stdout') { should include '/var/log/cloud-init.log' }
  its('stdout') { should include '/var/log/dnsmasq.log' }
  its('stdout') { should include '/var/log/dpkg.log' }
# TODO: perhaps remove this from common since it seems to only be present on ELK instances  
#  its('stdout') { should include '/var/log/fontconfig.log' }
  its('stdout') { should include '/var/log/grubfix.log' }
  its('stdout') { should include '/var/log/kern.log' }
# NOTE: this does not seem to be used on the jumphost
#  its('stdout') { should include '/var/log/landscape/sysinfo.log' }
  its('stdout') { should include '/var/log/mail.log' }
  its('stdout') { should include '/var/log/messages' }
# TODO: add once we have a test for proxy and proxy cache.
#  its('stdout') { should include '/var/log/squid/access.log' }
#  its('stdout') { should include '/var/log/squid/cache.log' }
  its('stdout') { should include '/var/log/sysctlfix.log' }
  its('stdout') { should include '/var/log/syslog' }
  its('stdout') { should include '/var/log/unattended-upgrades/unattended-upgrades-shutdown.log' }
end

# filebeat is harvesting instance specific logs
describe command("grep 'Harvester started for file' /var/log/filebeat/filebea* | awk '{print $NF}' | sort | uniq") do
  its('stdout') { should include '/var/log/nginx/access.log' }
  its('stdout') { should include '/var/log/nginx/error.log' }
  its('stdout') { should include '/var/log/nginx/fancy_access.log' }
# TODO: add once we have a test for the piv-cac cron tasks.
#  its('stdout') { should include '/srv/pki-rails/shared/log/cron.log' }
  its('stdout') { should include '/srv/pki-rails/shared/log/production.log' }
  its('stdout') { should include '/srv/pki-rails/shared/log/newrelic_agent.log' }
end
