# Inspec tests for idp node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# ensure that node.js v8.* is installed
describe command('node --version') do
  its('exit_status') { should eq 0 }
  its('stdout') { should start_with('v8.') }
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

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end

# check passenger status
#
# For unclear reasons, the passenger registry dir shows up in
# /var/lib/kitchen/cache/, but only on Ubuntu 14.04. This can be removed once
# we're fully on ubuntu 16.04.
# See: https://stackoverflow.com/questions/31761542/phusion-passenger-status-what-value-for-passenger-instance-registry-dir#31769807
if os[:release] == '14.04'
  passenger_registry_dir='/var/lib/kitchen/cache/'
else
  passenger_registry_dir='/tmp/'
end
describe command("sudo env PASSENGER_INSTANCE_REGISTRY_DIR=#{passenger_registry_dir} passenger-status") do
  its('exit_status') { should eq 0 }
  its('stdout') { should include 'General information' }
end

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end

describe file('/var/log/nginx/access.log') do
  it { should exist }
end

# check deploy info file
describe file('/srv/idp/current/public/api/deploy.json') do
  it { should be_file }
  its('content') { should match(/"user": "chef"/) }
  its('content') { should match(/^\s*"sha": "[0-9a-f]{40}"/) }
  its('content') { should match(/^\s*"git_sha": "[0-9a-f]{40}"/) }
end


describe file('/srv/idp/shared/config/application.yml') do
  it { should_not exist }
end
describe file('/srv/idp/shared/config/database.yml') do
  it { should_not exist }
end

describe file('/srv/idp/current/config/application.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  it { should_not be_readable.by('others') }
  it { should be_readable.by_user('websrv') }
  its('content') { should include('production:') }
  its('content') { should include('database_host') }
end

describe file('/srv/idp/current/config/database.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
end

# hit the IDP database health check and ensure it's healthy
# Ideally we would use the http() inspec resource, but it doesn't seem to work
describe command('curl -Sfk -i https://localhost/api/health/database') do
  its('exit_status') { should eq 0 }
  its('stdout') { should start_with("HTTP/1.1 200 OK") }
  its('stdout') { should include 'Content-Type: application/json' }
  its('stdout') { should include '"healthy":true' }
end
