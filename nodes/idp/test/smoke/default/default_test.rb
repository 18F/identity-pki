# encoding: utf-8
require 'rspec/retry'

RSpec.configure do |config|
  # show retry status in spec process
  # config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  # config.display_try_failure_messages = true
end

# Inspec tests for idp node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# ensure that node.js v12.* is installed
describe command('node --version') do
  its('exit_status') { should eq 0 }
  its('stdout') { should start_with('v12.') }
end

# check that passenger is installed and running
describe service('passenger') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe command('sudo systemctl show passenger -p SubState') do
  its('stdout') { should eq "SubState=running\n" }
end

describe command('sudo systemctl is-enabled passenger') do
  its('exit_status') { should eq 0 }
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

describe file('/opt/nginx/logs') do
  it { should be_linked_to '/var/log/nginx' }
end

# should not run migrations on idp
describe file('/tmp/ran-deploy-migrate') do
  it { should_not exist }
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
  its('content') { should include('"suffix":"2020"') }
end

describe file('/srv/idp/current/config/database.yml') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
end

describe http('https://localhost/api/health', ssl_verify: false) do
  its('status') { should eq 200 }
  its('headers.Content-Type') { should cmp 'application/json; charset=utf-8' }
  its('body') { should include '"all_checks_healthy":true' }
end

describe http('https://localhost', ssl_verify: false) do
  its('status') { should eq 200 }
  its('headers.Content-Type') { should cmp 'text/html; charset=utf-8' }
  its('body') { should include 'Sign in' }
end

# make sure we're writing to production log
describe file('/srv/idp/shared/log/production.log') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  its(:size) { should > 0 }
end

describe file('/var/log/nginx/access.log') do
  it { should exist }
  its(:size) { should > 0 }
end

# Ensure our nginx configuration is a valid one.
describe command('/opt/nginx/sbin/nginx -t') do
  its('exit_status') { should eq 0 }
end

describe port(443) do
  it { should be_listening }
end

# verify certs and hit the IDP SAML 2020 metadata endpoint
describe file('/srv/idp/shared/certs/saml2020.crt') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  its('owner') { should eq 'appinstall' }
  its(:size) { should > 0 }
end

describe file('/srv/idp/shared/keys/saml2020.key.enc') do
  it { should exist }
  it { should be_file }
  it { should_not be_symlink }
  it { should_not be_readable.by('others') }
  it { should be_readable.by('group') }
  its('owner') { should eq 'appinstall' }
  its(:size) { should > 0 }
end

describe http('https://localhost/api/saml/metadata2020', ssl_verify: false) do
  its('status') { should eq 200 }
  its('headers.Content-Type') { should cmp 'text/xml; charset=utf-8' }
  its('body') { should include '<SingleSignOnService' }
end

# idp-jobs service
describe processes(/rake job_runs:run/) do
  it { should exist }

  # there should be exactly one job run service process
  its('entries.length') { should eq 1 }

  # should be running as websrv
  its('users') { should eq ['websrv'] }
end

describe service('filebeat') do
  it { should be_installed }
  it { should be_enabled }
end

# filebeat is harvesting common logs
describe file('/var/log/filebeat/filebeat') do
  its('content') { should include '/var/log/alternatives.log' }
  its('content') { should include '/var/log/amazon/ssm/amazon-ssm-agent.log' }
  its('content') { should include '/var/log/amazon/ssm/errors.log' }
  its('content') { should include '/var/log/amazon/ssm/hibernate.log' }
  its('content') { should include '/var/log/apport.log' }
  its('content') { should include '/var/log/apt/history.log' }
  its('content') { should include '/var/log/apt/term.log' }
  its('content') { should include '/var/log/audit/audit.log' }
  its('content') { should include '/var/log/auth.log' }
# TODO: add once we either test the awsagent update process or the build of this instance takes long
# enough for the awsagent update to occur automatically.
#  its('content') { should include '/var/log/awsagent-update.log' }
  its('content') { should include '/var/log/awslogs-agent-setup.log' }
  its('content') { should include '/var/log/awslogs.log' }
  its('content') { should include '/var/log/clamav/clamav.log' }
# TODO: add once we have a test that updates the clamav definitions.
  its('content') { should include '/var/log/clamav/freshclam.log' }
  its('content') { should include '/var/log/cloud-init-output.log' }
  its('content') { should include '/var/log/cloud-init.log' }
  its('content') { should include '/var/log/dnsmasq.log' }
  its('content') { should include '/var/log/dpkg.log' }
# TODO: perhaps remove this from common since it seems to only be present on ELK instances  
#  its('content') { should include '/var/log/fontconfig.log' }
  its('content') { should include '/var/log/grubfix.log' }
  its('content') { should include '/var/log/kern.log' }
# NOTE: this does not seem to be used on the jumphost
#  its('content') { should include '/var/log/landscape/sysinfo.log' }
  its('content') { should include '/var/log/mail.log' }
  its('content') { should include '/var/log/messages' }
# TODO: add once we have a test for proxy and proxy cache.
#  its('content') { should include '/var/log/squid/access.log' }
#  its('content') { should include '/var/log/squid/cache.log' }
  its('content') { should include '/var/log/sysctlfix.log' }
  its('content') { should include '/var/log/syslog' }
  its('content') { should include '/var/log/unattended-upgrades/unattended-upgrades-shutdown.log' }
end

# filebeat is harvesting instance specific logs
describe file('/var/log/filebeat/filebeat') do
  it 'should include events.log', retry: 3, retry_wait: 20 do
    expect(file('/var/log/filebeat/filebeat').content).to include('/srv/idp/shared/log/events.log')
  end
  it 'should include kms.log', retry: 3, retry_wait: 20 do
    expect(file('/var/log/filebeat/filebeat').content).to include('/srv/idp/shared/log/kms.log')
  end
  its('content') { should include '/srv/idp/shared/log/newrelic_agent.log' }
  its('content') { should include '/var/log/nginx/access.log' }
  its('content') { should include '/var/log/nginx/error.log' }
  its('content') { should include '/var/log/nginx/fancy_access.log' }
  its('content') { should include '/srv/idp/shared/log/production.log' }
end

describe file('/opt/nginx/conf/sites.d/idp_web.conf') do
  it { should exist }
  its(:size) { should > 0 }
  its('content') { should include("server_name  ci.identitysandbox.gov ;") }
  its('content') { should include("return       302  https://idp.ci.identitysandbox.gov$request_uri;") }
end

describe service('metricbeat') do
  it { should be_installed }
  it { should be_enabled }
end
