# # encoding: utf-8

# Inspec tests for worker node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('monit') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe processes('sidekiq') do
  it { should exist }

  # there should be exactly one sidekiq process
  its('entries.length') { should eq 1 }

  # should be running as ubuntu user (TODO)
  its('users') { should eq ['ubuntu'] }
end

describe port(80) do
  it { should_not be_listening }
end

describe port(443) do
  it { should_not be_listening }
end

describe processes('rails') do
  it { should_not exist }
end
