# # encoding: utf-8

# Inspec tests for worker node

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
