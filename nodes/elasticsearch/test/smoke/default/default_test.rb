# # encoding: utf-8

# Inspec tests for elasticsearch node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('ssh') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe command('java -version') do
  its(:stderr) { should include 'openjdk version'  }
end

describe service('elasticsearch') do
  it { should be_enabled }
  it { should be_running }
end

describe port(9200) do
  it { should be_listening }
end

describe port(9300) do
  it { should be_listening }
end

describe command('wget -O - --ca-certificate /etc/elasticsearch/root-ca.pem https://localhost:9200/') do
  its('stdout') { should match 'tagline.*You Know, for Search' }
end

describe command('wget -O - --ca-certificate /etc/elasticsearch/root-ca.pem https://localhost:9200/_cluster/health?pretty=true') do
  its('stdout') { should match '"cluster_name" : "elasticsearch"' }
  its('stdout') { should match '"status" : "green"' }
end

control 'check-cert-setup' do

  environment = file("/etc/login.gov/info/env")
  describe environment do
    it { should exist }
    it { should be_file }
  end

  hostname = command("hostname")
  describe hostname do
    its('exit_status') { should eq 0 }
    its('stdout') { should match "elasticsearch-i-[0-9a-z]*.#{environment.content.chomp}.login.gov" }
  end

  # check for node tls cert
  ip = command("hostname -I").stdout.strip
  describe file("/etc/elasticsearch/#{ip}.pem") do
    it { should exist }
    it { should be_file }
  end

  # check for node http cert
  describe file("/etc/elasticsearch/#{ip}.pem") do
    it { should exist }
    it { should be_file }
  end

  # check and verify admin (client) keystore
  storepass = 'not-a-secret'
  keystore_contents = command("sudo keytool -list -keystore /etc/elasticsearch/admin.jks -storepass #{storepass}")
  describe keystore_contents do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'Your keystore contains 1 entry' }
    its('stdout') { should match 'admin,.*PrivateKeyEntry' }
  end

  # check and verify truststore
  truststore_contents = command("sudo keytool -list -keystore /etc/elasticsearch/truststore.jks -storepass #{storepass}")
  describe truststore_contents do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'Your keystore contains 1 entry' }
    its('stdout') { should match 'root.login.gov.internal,.*trustedCertEntry' }
  end
end

discovery_cron_cmd = %q(flock -n /tmp/es_setup.lock -c "cat /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb >/dev/null && chef-client --local-mode -c /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb -o 'role[elasticsearch_discovery]' 2>&1 >> /var/log/elasticsearch/discovery.log")

describe crontab('root') do
  its('commands') { should include discovery_cron_cmd }
end
describe crontab('root').commands(discovery_cron_cmd) do
  its('minutes') { should cmp '0,15,30,45' }
end

# Ensure we can export ES metrics to New Relic.
describe command('/opt/newrelic-infra/elasticsearch_health/es_health') do
  its(:exit_status) { should eq 0 }
end

# It should have a valid platinum license subscription
describe command('wget -O - --ca-certificate /etc/elasticsearch/root-ca.pem https://localhost:9200/_xpack/license') do
  its('stdout') { should match '"type" : "platinum"' }
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
  its('content') { should include '/var/log/elasticsearch/discovery.log' }
  its('content') { should include '/var/log/elasticsearch/elasticsearch.log' }
  its('content') { should include '/var/log/elasticsearch/elasticsearch_deprecation.log' }
  its('content') { should include '/var/log/elasticsearch/elasticsearch_index_indexing_slowlog.log' }
  its('content') { should include '/var/log/elasticsearch/elasticsearch_index_search_slowlog.log' }
end
