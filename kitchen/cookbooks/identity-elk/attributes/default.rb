# Elasticsearch Domain.  By default it is "es.login.gov.internal" for non auto
# scaled instances, and "elasticsearch.login.gov.internal" for auto scaled
# instances.  This is because the auto scaled instances are behind an ELB so
# that they can be dynamically created and destroyed, while the non auto scaled
# instances get explicitly added to a DNS record by terraform.
default['es']['domain'] = "elasticsearch.login.gov.internal"

# logfiles to watch
default['elk']['filebeat']['logfiles'] = [
  {'log' => '/srv/*/shared/log/events.log', 'type' => 'log', 'format' => 'json'},
  {'log' => '/srv/*/shared/log/production.log', 'type' => 'log', 'format' => 'text'},
  {'log' => '/srv/*/shared/log/newrelic_agent.log', 'type' => 'log', 'format' => 'text'},
  {'log' => '/var/log/syslog', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/log/auth.log', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/lib/docker/aufs/mnt/*/var/log/*/*.log', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/log/dnsmasq.log', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/log/*/current', 'type' => 'log', 'format' => 'text'},
  {'log' => '/var/log/opscode/*/current', 'type' => 'cheflog', 'format' => 'text'},
  {'log' => '/var/log/opscode/*/*.log', 'type' => 'cheflog', 'format' => 'text'},
  {'log' => '/var/log/postgres/*', 'type' => 'pglog', 'format' => 'text'},
  {'log' => '/var/log/*/*.log', 'type' => 'syslog', 'format' => 'text'}
]

# set filebeat to do logstash output
default['filebeat']['config']['output']['logstash']['enable'] = true
default['filebeat']['config']['output']['logstash']['loadbalance'] = true
default['filebeat']['config']['output']['logstash']['save_topology'] = false
default['filebeat']['config']['output']['logstash']['index'] = 'filebeat'
default['filebeat']['config']['output']['logstash']['tls']['certificate_authorities'] = ["/etc/ssl/certs/ca-certificates.crt"]

# how many days to keep logs around in ELK
default['elk']['retentiondays'] = 30

# indexes to prune.  Can be figured out with curl 'localhost:9200/_cat/indices?v'
default['elk']['indextypes'] = [
  'logstash',
  'filebeat'
]

# Set this to false in environments that use new-style bucket names.
default['elk']['legacy_log_bucket_name'] = true

# get a modern version of java
default['java']['jdk_version'] = '8'

# remote files
default['elk']['kibanatarball'] = 'https://artifacts.elastic.co/downloads/kibana/kibana-6.8.2-linux-x86_64.tar.gz'
default['elk']['logstashdeb'] = 'https://artifacts.elastic.co/downloads/logstash/logstash-6.8.2.deb'
default['elk']['logstash-input-cloudwatch-logs-version'] = '1.0.3'
default['elk']['logstash-codec-cloudtrail-version'] = '3.0.5'

# users to allow into elk
default['elk']['users'] = [ ]

# set this so that we listen on 8443
default['apache']['listen'] = [8443]


default['elk']['logstash']['log_level'] = 'info'
default['elk']['logstash']['path_data'] = '/var/lib/logstash'
default['elk']['logstash']['path_logs'] = '/var/log/logstash'
default['elk']['logstash']['xpack_monitoring_enabled'] = true
default['elk']['logstash']['xpack_monitoring_elasticsearch_url'] = 'https://elasticsearch.login.gov.internal:9200'
default['elk']['logstash']['xpack_monitoring_elasticsearch_ssl_ca'] = '/etc/elasticsearch/root-ca.pem'

default['elk']['elastalert']['version'] = 'v0.1.39'
# If the list of emails is empty, then do not email.
default['elk']['elastalert']['emails'] = []

# curator config
default['elasticsearch-curator']['config'] = {
  'client' => {
    'hosts' => [node.fetch("es").fetch("domain")],
    'port' => 9200,
    'use_ssl' => true,
    'ssl_no_validate' => true,
    'timeout' => 30,
    'master_only' => false
  },
  'logging' => {
    'loglevel' => 'INFO',
    'logformat' => 'default'
  }
}

# dir to put postgres logs in
default['elk']['pglogsdir'] = '/var/log/postgres'

# Service discovery
default['elk']['es_tag_key'] = "prefix"
default['elk']['es_tag_value'] = "elasticsearch"
default['elk']['elk_tag_key'] = "prefix"
default['elk']['elk_tag_value'] = "elk"

# CloudWatch log groups to ingest
default['elk']['logstash']['cloudwatch']['audit-aws']['enable'] = true
default['elk']['logstash']['cloudwatch']['audit-github']['enable'] = true
default['elk']['logstash']['cloudwatch']['flowlog']['enable'] = true
default['elk']['logstash']['cloudwatch']['kms']['enable'] = true
default['elk']['logstash']['cloudwatch']['postgresql']['enable'] = true
default['elk']['logstash']['cloudwatch']['waf']['enable'] = false

# For adding chef discovery cron job
default['elk']['chef_zero_client_configuration'] = '/etc/login.gov/repos/identity-devops/kitchen/chef-client.rb'

# change this per env to transition over to the account-specific logbuckets
#default['elk']['aws_logging_bucket'] = "login-gov-logs-${node.chef_environment}.${aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
if node['elk']['legacy_log_bucket_name']
  default['elk']['aws_logging_bucket'] = "login-gov-#{node.chef_environment}-logs"
  default['elk']['analytics_logging_bucket'] = "login-gov-#{node.chef_environment}-analytics-logs"
else
  default['elk']['aws_logging_bucket'] = "login-gov-logs-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
  default['elk']['analytics_logging_bucket'] = "login-gov-analytics-logs-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
end
default['elk']['elb_logging_bucket'] = "login-gov.elb-logs.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
default['elk']['waf_logging_bucket'] = "login-gov.waf-logs-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
default['elk']['analytics_logging_bucket'] = "login-gov.analytics-logs-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"

# use this to turn off analytics logging support
default['elk']['analytics_logs'] = true
