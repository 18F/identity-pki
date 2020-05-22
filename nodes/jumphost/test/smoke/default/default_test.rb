# Inspec tests for Jumphost node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

# make sure that identity-devops-private provisioning completed
describe file('/run/private-provisioning') do
  it { should exist }
end

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/usr/local/bin/id-chef-client') do
  it { should exist }
  it { should be_executable }
end

describe file('/etc/login.gov/info/auto-scaled') do
  it { should exist }
end

# base image tests -- these should be satisfied by the base AMI

# dateext set in logrotate
describe file('/etc/logrotate.conf') do
  it { should exist }
  its('content') { should include('dateext') }
end

# hostname set to something reasonable by auto-hostname
describe file('/usr/local/bin/auto-set-ec2-hostname') do
  it { should exist }
end
describe sys_info do
  its('hostname') { should match(/\.(login|identitysandbox)\.gov\z/) }
end

[22, 26].each do |ssh_port|
  describe port(ssh_port) do
    its('processes') { should include 'sshd' }
    its('protocols') { should include 'tcp' }
    its('addresses') { should include '0.0.0.0' }
  end
end

# time sync enabled
describe command('timedatectl status') do
  its('stdout') { should include 'System clock synchronized: yes' }
end

# proxy configs
describe os_env('https_proxy') do
  its('content') { should eq 'http://obproxy.login.gov.internal:3128' }
end
describe file('/etc/login.gov/info/http_proxy') do
  it { should exist }
  its('content') { should eq "http://obproxy.login.gov.internal:3128\n" }
end
describe file('/etc/login.gov/info/proxy_server') do
  it { should exist }
  its('content') { should eq "obproxy.login.gov.internal\n" }
end
describe file('/etc/login.gov/info/proxy_port') do
  it { should exist }
  its('content') { should eq "3128\n" }
end
describe file('/etc/environment') do
  its('content') { should include("http_proxy='http://obproxy.login.gov.internal:3128'") }
end

#
# Filebeat tests
#
describe service('filebeat') do
  it { should be_installed }
  it { should be_enabled }
end

# filebeat is harvesting common logs
describe file('/var/log/filebeat/filebeat') do
  its('content') { should include '/var/log/alternatives.log' }
  its('content') { should include '/var/log/amazon/ssm/amazon-ssm-agent.log' }
  its('content') { should include '/var/log/amazon/ssm/errors.log' }
  its('content') { should include '/var/log/amazon/ssm/hibernate.log' }
  its('content') { should include '/var/log/apport.log' }
  its('content') { should include '/var/log/apt/history.log' }
  its('content') { should include '/var/log/apt/term.log' }
  its('content') { should include '/var/log/audit/audit.log' }
  its('content') { should include '/var/log/auth.log' }
# TODO: add once we either test the awsagent update process or the build of this instance takes long
# enough for the awsagent update to occur automatically.
#  its('content') { should include '/var/log/awsagent-update.log' }
  its('content') { should include '/var/log/awslogs-agent-setup.log' }
  its('content') { should include '/var/log/awslogs.log' }
  its('content') { should include '/var/log/clamav/clamav.log' }
# TODO: add once we have a test that updates the clamav definitions.
  its('content') { should include '/var/log/clamav/freshclam.log' }
  its('content') { should include '/var/log/cloud-init-output.log' }
  its('content') { should include '/var/log/cloud-init.log' }
  its('content') { should include '/var/log/dnsmasq.log' }
  its('content') { should include '/var/log/dpkg.log' }
# TODO: perhaps remove this from common since it seems to only be present on ELK instances  
#  its('content') { should include '/var/log/fontconfig.log' }
  its('content') { should include '/var/log/grubfix.log' }
  its('content') { should include '/var/log/kern.log' }
# NOTE: this does not seem to be used on the jumphost
#  its('content') { should include '/var/log/landscape/sysinfo.log' }
  its('content') { should include '/var/log/mail.log' }
  its('content') { should include '/var/log/messages' }
# TODO: add once we have a test for proxy and proxy cache.
#  its('content') { should include '/var/log/squid/access.log' }
#  its('content') { should include '/var/log/squid/cache.log' }
  its('content') { should include '/var/log/sysctlfix.log' }
  its('content') { should include '/var/log/syslog' }
  its('content') { should include '/var/log/unattended-upgrades/unattended-upgrades-shutdown.log' }
end

describe service('metricbeat') do
  it { should be_installed }
  it { should be_enabled }
end
