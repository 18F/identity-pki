# # encoding: utf-8

# Inspec tests for proxy node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('proxy') do
  it { should exist }
end

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('squid') do
  it { should be_installed }
  it { should be_enabled }
end

describe port(3128) do
  it { should be_listening }
  its('processes') {should include 'squid'}
end

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end

# should not be set up to use the proxy ourselves
describe os_env('http_proxy') do
  its('content') { should be_in [nil, ''] }
end
describe os_env('https_proxy') do
  its('content') { should be_in [nil, ''] }
end
describe file('/etc/login.gov/info/http_proxy') do
  it { should exist }
  its('size') { should eq 0 }
end
describe file('/etc/login.gov/info/proxy_server') do
  it { should exist }
  its('size') { should eq 0 }
end
describe file('/etc/environment') do
  its('content') { should_not match(/http_proxy=.../) }
  its('content') { should_not match(/https_proxy=.../) }
end

# test proxy HTTP
describe command('curl -sSf -m 5 --proxy http://localhost:3128 https://checkip.amazonaws.com') do
  its('stderr') { should eq '' }
  its('stdout') { should match(/\A\d+\.\d+\.\d+\.\d+/) }
  its('exit_status') { should eq 0 }
end

# test proxy HTTP denial
describe command('curl -sSf -m 5 --proxy http://localhost:3128 https://denial-test.example.com') do
  its('stderr') { should eq "curl: (22) The requested URL returned error: 403\n" }
  its('stdout') { should eq '' }
  its('exit_status') { should eq 22 }
end

# test proxy port based denial
describe command('curl -sSf -m 5 --proxy http://localhost:3128 https://checkip.amazonaws.com:22') do
  its('stderr') { should eq "curl: (22) The requested URL returned error: 403\n" }
  its('stdout') { should eq '' }
  its('exit_status') { should eq 22 }
end
