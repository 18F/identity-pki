# # encoding: utf-8

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
