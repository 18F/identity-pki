# # encoding: utf-8

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
# TODO: this should work with the .on predicate to specify the interface that the port is listening
# on however it results in the following error:
# undefined method `on' for #<RSpec::Matchers::BuiltIn::BePredicate:0x00007fe6377ae750>
#  it { should be_listening.on('127.0.0.1') }
  it { should be_listening }
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
describe command("grep 'Harvester started for file' /var/log/filebeat/filebea* | awk '{print $NF}' | sort | uniq") do
  its('stdout') { should include '/var/log/alternatives.log' }
  its('stdout') { should include '/var/log/amazon/ssm/amazon-ssm-agent.log' }
  its('stdout') { should include '/var/log/amazon/ssm/errors.log' }
  its('stdout') { should include '/var/log/amazon/ssm/hibernate.log' }
  its('stdout') { should include '/var/log/apport.log' }
  its('stdout') { should include '/var/log/apt/history.log' }
  its('stdout') { should include '/var/log/apt/term.log' }
  its('stdout') { should include '/var/log/audit/audit.log' }
  its('stdout') { should include '/var/log/auth.log' }
# TODO: add once we either test the awsagent update process or the build of this instance takes long
# enough for the awsagent update to occur automatically.
#  its('stdout') { should include '/var/log/awsagent-update.log' }
  its('stdout') { should include '/var/log/awslogs-agent-setup.log' }
  its('stdout') { should include '/var/log/awslogs.log' }
  its('stdout') { should include '/var/log/clamav/clamav.log' }
# TODO: add once we have a test that updates the clamav definitions.
  its('stdout') { should include '/var/log/clamav/freshclam.log' }
  its('stdout') { should include '/var/log/cloud-init-output.log' }
  its('stdout') { should include '/var/log/cloud-init.log' }
  its('stdout') { should include '/var/log/dnsmasq.log' }
  its('stdout') { should include '/var/log/dpkg.log' }
# TODO: perhaps remove this from common since it seems to only be present on ELK instances
#  its('stdout') { should include '/var/log/fontconfig.log' }
  its('stdout') { should include '/var/log/grubfix.log' }
  its('stdout') { should include '/var/log/kern.log' }
# NOTE: this does not seem to be used on the jumphost
#  its('stdout') { should include '/var/log/landscape/sysinfo.log' }
  its('stdout') { should include '/var/log/mail.log' }
  its('stdout') { should include '/var/log/messages' }
# TODO: add once we have a test for proxy and proxy cache.
#  its('stdout') { should include '/var/log/squid/access.log' }
#  its('stdout') { should include '/var/log/squid/cache.log' }
  its('stdout') { should include '/var/log/sysctlfix.log' }
  its('stdout') { should include '/var/log/syslog' }
  its('stdout') { should include '/var/log/unattended-upgrades/unattended-upgrades-shutdown.log' }
end

# filebeat is harvesting instance specific logs
describe command("grep 'Harvester started for file' /var/log/filebeat/filebea* | awk '{print $NF}' | sort | uniq") do
  its('stdout') { should include '/var/log/apache2/access.log' }
# TODO: add once we have a test that confirms Apache error conditions.
#  its('stdout') { should include '/var/log/apache2/error.log' }
# TODO: add once we have a test that confirms events that log to this file.
#  its('stdout') { should include '/var/log/apache2/other_vhosts_access.log' }
  its('stdout') { should include '/var/log/cloudtraillogstash/current' }
  its('stdout') { should include '/var/log/cloudwatchlogstash/current' }
  its('stdout') { should include '/var/log/kibana/current' }
  its('stdout') { should include '/var/log/logstash/current' }
# TODO: add once we have a test that confirms events that log to this file.
#  its('stdout') { should include '/var/log/logstash/logstash-plain.log' }
# TODO: add once we have a test to introduce a slowlog event.
#  its('stdout') { should include '/var/log/logstash/logstash-slowlog-plain.log' }
end
