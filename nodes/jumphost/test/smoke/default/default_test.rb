# Inspec tests for Jumphost node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/usr/local/bin/terraform') do
  it { should exist }
  it { should be_executable }
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
