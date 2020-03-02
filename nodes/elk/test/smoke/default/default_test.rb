# encoding: utf-8
require 'rspec/retry'

RSpec.configure do |config|
  # show retry status in spec process
  # config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  # config.display_try_failure_messages = true
end

# Inspec tests for elk node
# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('apache2') do
  it { should be_enabled }
  it { should be_running }
end

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe runit_service('cloudtraillogstash') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe runit_service('cloudwatchlogstash') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe runit_service('elastalert') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe runit_service('kibana') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe runit_service('logstash') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# kibana
describe port(5601) do
  it 'should be addressable on 127.0.0.1', retry: 6, retry_wait: 60 do
    expect(port(5601).addresses).to include('127.0.0.1')
  end
  it 'should have its processed owned by node', retry: 6, retry_wait: 60 do
    expect(port(5601).processes).to include('node')
  end
  it 'should be_listening', retry: 6, retry_wait: 60 do
    should be_listening
  end
end

# apache https proxy to kibana
describe port(8443) do
  it { should be_listening }
end

discovery_cron_cmd = %q(flock -n /tmp/elk_discovery.lock -c "cat /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb >/dev/null && chef-client --local-mode -c /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb -o 'role[elk_discovery]' 2>&1 >> /var/log/elk-discovery.log")

describe crontab('root') do
  its('commands') { should include discovery_cron_cmd }
end

describe crontab('root').commands(discovery_cron_cmd) do
  its('minutes') { should cmp '0,15,30,45' }
end

LOGSTASH_CONFIG_DIRECTORIES = ['cloudtraillogstashconf.d',
                               'cloudwatchlogstashconf.d',
                               'logstashconf.d'].freeze

LOGSTASH_CONFIG_DIRECTORIES.each do |config_dir|
  describe command("/usr/share/logstash/bin/logstash -f /etc/logstash/#{config_dir} --config.test_and_exit") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'Configuration OK' }
  end
end

describe service('filebeat') do
  it { should be_installed }
  it { should be_enabled }
end

# filebeat is harvesting common logs
describe file('/var/log/filebeat/filebeat') do
# TODO: add once we test something that creates entries in the alternatives log.
#  its('content') { should include '/var/log/alternatives.log' }
  its('content') { should include '/var/log/amazon/ssm/amazon-ssm-agent.log' }
  its('content') { should include '/var/log/amazon/ssm/errors.log' }
# TODO: add once we test something that creates entries in the amazon/ssm/hibernate.log.
#  its('content') { should include '/var/log/amazon/ssm/hibernate.log' }
  its('content') { should include '/var/log/apport.log' }
# TODO: add once we test something that creates entries in the audit log.
#  its('content') { should include '/var/log/audit/audit.log' }
  its('content') { should include '/var/log/auth.log' }
# TODO: add once we either test the awsagent update process or the build of this instance takes long
# enough for the awsagent update to occur automatically.
#  its('content') { should include '/var/log/awsagent-update.log' }
  its('content') { should include '/var/log/awslogs-agent-setup.log' }
  its('content') { should include '/var/log/awslogs.log' }
# TODO: add once we have a test that assures clamav is running.
#  its('content') { should include '/var/log/clamav/clamav.log' }
# TODO: add once we have a test that updates the clamav definitions.
#  its('content') { should include '/var/log/clamav/freshclam.log' }
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
end

# filebeat is harvesting instance specific logs
describe file('/var/log/filebeat/filebeat') do
# TODO: add once we have a test that confirms events that log to this file.
#  its('content') { should include '/var/log/apache2/access.log' }
# TODO: add once we have a test that confirms Apache error conditions.
#  its('content') { should include '/var/log/apache2/error.log' }
# TODO: add once we have a test that confirms events that log to this file.
#  its('content') { should include '/var/log/apache2/other_vhosts_access.log' }
  its('content') { should include '/var/log/cloudtraillogstash/current' }
  its('content') { should include '/var/log/cloudwatchlogstash/current' }
  its('content') { should include '/var/log/kibana/current' }
  its('content') { should include '/var/log/logstash/current' }
# TODO: add once we have a test that confirms events that log to this file.
#  its('content') { should include '/var/log/logstash/logstash-plain.log' }
# TODO: add once we have a test to introduce a slowlog event.
#  its('content') { should include '/var/log/logstash/logstash-slowlog-plain.log' }
end
