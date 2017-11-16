# encoding: utf-8

# Inspec tests for App (dashboard / sample sp) node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end

# check that passenger is installed and running
if os[:release] == '14.04'
  describe service('passenger') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
else
  # Ubuntu >= 16.04 runs systemd

  describe service('passenger') do
    it { should be_installed }
    # enabled check appears broken on systemd with inspec 1.43
    #it { should be_enabled }
    it { should be_running }
  end

  describe command('sudo systemctl show passenger -p SubState') do
    its('stdout') { should eq "SubState=running\n" }
  end

  describe command('sudo systemctl is-enabled passenger') do
    its('exit_status') { should eq 0 }
  end
end

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end

describe file('/var/log/nginx/access.log') do
  it { should exist }
end

# TODO: actually test that sp-rails, dashboard, sp-sinatra, etc. are working
