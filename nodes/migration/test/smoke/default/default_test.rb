# Inspec tests for migration node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# ensure that node.js v12.* is installed
describe command('node --version') do
  its('exit_status') { should eq 0 }
  its('stdout') { should start_with('v12') }
end

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end

# should run migrations on migration servers
describe file('/tmp/ran-deploy-migrate') do
  it { should exist }
end

# check deploy info file
describe file('/srv/idp/current/public/api/deploy.json') do
  it { should be_file }
  its('content') { should match(/"user": "chef"/) }
  its('content') { should match(/^\s*"sha": "[0-9a-f]{40}"/) }
  its('content') { should match(/^\s*"git_sha": "[0-9a-f]{40}"/) }
end

describe file('/srv/idp/shared/config/application.yml') do
  it { should_not exist }
end
describe file('/srv/idp/shared/config/database.yml') do
  it { should_not exist }
end

describe file('/srv/idp/current/config/application.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  it { should_not be_readable.by('others') }
  it { should be_readable.by_user('websrv') }
  its('content') { should include('production:') }
  its('content') { should include('database_host') }
end

describe file('/srv/idp/current/config/database.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
end

# make sure we're writing to production log
# TODO: replace this with wherever we decide to put migration logs
#describe file('/srv/idp/shared/log/production.log') do
#  it { should exist }
#  it { should be_file }
#  it { should_not be_symlink }
#  its(:size) { should > 0 }
#end

describe file('/var/log/nginx/access.log') do
  it { should exist }
end

# idp-jobs service should not be running
describe processes(/rake job_runs:run/) do
  it { should_not exist }
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
  its('stdout') { should include '/srv/idp/shared/log/newrelic_agent.log' }
  its('stdout') { should include '/var/log/nginx/access.log' }
  its('stdout') { should include '/var/log/nginx/error.log' }
  its('stdout') { should include '/var/log/nginx/fancy_access.log' }
  its('stdout') { should include '/srv/idp/shared/log/production.log' }
end
