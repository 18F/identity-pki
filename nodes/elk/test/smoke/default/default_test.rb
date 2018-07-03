# # encoding: utf-8

# Inspec tests for elk node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe port(8443) do
  it { should be_listening }
end

describe service('apache2') do
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

discovery_cron_cmd = "cat /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb >/dev/null && chef-client --local-mode -c /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb -o 'role[elk_discovery]' 2>&1 >> /var/log/elk-discovery.log"

describe crontab('root') do
  its('commands') { should include discovery_cron_cmd }
end
describe crontab('root').commands(discovery_cron_cmd) do
  its('minutes') { should cmp '0,15,30,45' }
end
