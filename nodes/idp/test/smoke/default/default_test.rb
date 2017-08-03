# # encoding: utf-8

# Inspec tests for idp node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('test') do
  it { should exist }
end

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
describe command('sudo passenger-status') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include 'General information' }
end
