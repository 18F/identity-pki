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
