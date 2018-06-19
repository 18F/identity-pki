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
