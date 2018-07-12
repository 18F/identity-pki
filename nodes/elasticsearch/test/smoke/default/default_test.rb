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

control 'check-certs-trusted' do

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

  storepass = 'EipbelbyamyotsOjHod2'
  keystore_contents = command("sudo keytool -list -keystore /etc/elasticsearch/keystore.jks -storepass #{storepass}")
  describe keystore_contents do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'Your keystore contains 1 entry' }
    its('stdout') { should match '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*,.*PrivateKeyEntry' }
  end

  truststore_contents = command("sudo keytool -list -keystore /etc/elasticsearch/truststore.jks -storepass #{storepass}")
  describe truststore_contents do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'Your keystore contains [3-9] entries' }
    its('stdout') { should match 'elasticsearch.login.gov.internal,.*trustedCertEntry' }
    its('stdout') { should match "#{hostname.stdout.chomp},.*trustedCertEntry" }
  end
end

discovery_cron_cmd = "cat /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb >/dev/null && chef-client --local-mode -c /etc/login.gov/repos/identity-devops/kitchen/chef-client.rb -o 'role[elasticsearch_discovery]' 2>&1 >> /var/log/elasticsearch/discovery.log"

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
