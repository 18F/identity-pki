# Inspec tests for App (dashboard / sample sp) node#

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/#

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end#

# make sure we can sudo
describe command('sudo whoami') do
  its('stdout') { should eq "root\n" }
  its('exit_status') { should eq 0 }
end#

# check that passenger is installed and running
describe service('passenger') do
  it { should be_installed }
  # enabled check appears broken on systemd with inspec 1.43
  #it { should be_enabled }
  it { should be_running }
end#

describe command('sudo systemctl show passenger -p SubState') do
  its('stdout') { should eq "SubState=running\n" }
end#

describe command('sudo systemctl is-enabled passenger') do
  its('exit_status') { should eq 0 }
end#

# check passenger status
describe command('sudo passenger-status') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include 'General information' }
end#

# Make sure at least something is being served over HTTP
# Ideally we would use the http() inspec resource, but it doesn't seem to work
describe command('curl -Sfk -i https://localhost/') do
  its('exit_status') { should eq 0 }
  its('stdout') { should start_with('HTTP/1.1 200 OK') }
  its('stdout') { should include 'Content-Type: text/html' }
  its('stdout') { should include '<title>login.gov - Partner Dashboard</title>' }
end#

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end#

# Check that nginx access logs are working
describe file('/var/log/nginx/access.log') do
  it { should exist }
  its(:size) { should > 0 }
end#

describe file('/opt/nginx/conf/sites.d/dashboard.login.gov.conf') do
  it { should exist }
  its(:size) { should > 0 }
  its('content') { should include("server_name  oidc-sinatra.ci.identitysandbox.gov ;") }
  its('content') { should include("return       302  https://ci-identity-oidc-sinatra.app.cloud.gov$request_uri;") }
  its('content') { should include("server_name  saml-sinatra.ci.identitysandbox.gov ;") }
  its('content') { should include("return       302  https://ci-identity-saml-sinatra.app.cloud.gov$request_uri;") }
end

describe service('metricbeat') do
  it { should be_installed }
  it { should be_enabled }
end
