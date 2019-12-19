# # encoding: utf-8

# Inspec tests for proxy node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('websrv') do
  it { should exist }
end
  
describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

renewal_config = file("/etc/letsencrypt/renewal/pivcac.ci.identitysandbox.gov.conf")
describe renewal_config do
  it { should exist }
  it { should be_file }
  # Make sure we aren't DOSing letsencrypt from CI.
  its('content') { should match (/acme-staging/) }
end

# check that passenger is installed and running
describe service('passenger') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/srv/pki-rails/current/config/application.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  it { should_not be_readable.by('others') }
  it { should be_readable.by_user('websrv') }
  its('content') { should include('production:') }
  its('content') { should include('secret_key_base') }
end

# Ensure we compiled passenger/nginx with the right OpenSSL.
# This test will break when you upgrade our OpenSSL. Sorry.
describe command('/opt/nginx/sbin/nginx -V') do
  its('exit_status') { should eq 0 }
  its('stderr') { should match (/built with OpenSSL 1.0.2t/) }
end

# Ensure our nginx configuration is a valid one.
describe command('/opt/nginx/sbin/nginx -t') do
  its('exit_status') { should eq 0 }
end

describe file('/usr/local/bin/update_cert_revocations') do
  it { should exist }
  it { should be_executable }
end

describe file('/usr/local/bin/update_letsencrypt_certs') do
  it { should exist }
  it { should be_executable }
end

describe port(443) do
  it { should be_listening }
end
