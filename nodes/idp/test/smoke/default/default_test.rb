# # encoding: utf-8

# Inspec tests for idp node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('passenger') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end

# check passenger status
# TODO: Actually move the instance registry dir to something more reasonable.
# See: https://stackoverflow.com/questions/31761542/phusion-passenger-status-what-value-for-passenger-instance-registry-dir#31769807
describe command('sudo env PASSENGER_INSTANCE_REGISTRY_DIR=/var/lib/kitchen/cache/ passenger-status') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include 'General information' }
end

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end

describe file('/var/log/nginx/access.log') do
  it { should exist }
end
