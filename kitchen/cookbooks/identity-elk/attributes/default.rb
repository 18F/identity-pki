# Elasticsearch Domain.  By default it is "es.login.gov.internal" for non auto
# scaled instances, and "elasticsearch.login.gov.internal" for auto scaled
# instances.  This is because the auto scaled instances are behind an ELB so
# that they can be dynamically created and destroyed, while the non auto scaled
# instances get explicitly added to a DNS record by terraform.
default['es']['domain'] = 'elasticsearch.login.gov.internal'
default['es']['sg_version'] = 'search-guard-7'
default['es']['sg_zip'] = '7.4.2-41.0.0'
default['es']['sg_zip_sum'] = '3a79cdd09888ee4f8f58c9a6351a532da11c5f0a42f4f772508f84123eda516c'
default['es']['sg_tls'] = '1.7.tar.gz'
default['es']['sg_tls_sum'] = '284492779edf037348375994a0f320cc1425bda149d56c3db0031014241e7110'

# how many days to keep logs around in ELK
default['elk']['retentiondays'] = 90

# indexes to prune.  Can be figured out with curl 'localhost:9200/_cat/indices?v'
default['elk']['indextypes'] = [
  'logstash-2',
  'logstash-cloudwatch',
  'logstash-cloudtrail'
]

default['elk']['extendedretentiondays'] = 90
default['elk']['extendeddayindextypes'] = [
  'logstash-cloudtrail',
]

# get a modern version of java
default['java']['jdk_version'] = '8'

# remote files
default['elk']['kibanatarball'] = 'https://artifacts.elastic.co/downloads/kibana/kibana-7.4.2-linux-x86_64.tar.gz'
default['elk']['logstashdeb'] = 'https://artifacts.elastic.co/downloads/logstash/logstash-7.4.2.deb'
default['elk']['logstash-input-cloudwatch-logs-version'] = '1.0.3'
default['elk']['logstash-codec-cloudtrail-version'] = '3.0.5'

# set this so that we listen on 8443
default['apache']['listen'] = [8443]

default['elk']['logstash']['log_level'] = 'info'
default['elk']['logstash']['path_data'] = '/var/lib/logstash'
default['elk']['logstash']['path_logs'] = '/var/log/logstash'
default['elk']['logstash']['workers_count'] = node.fetch('cpu').fetch('total')
default['elk']['logstash']['xpack_monitoring_enabled'] = true
default['elk']['logstash']['xpack_monitoring_elasticsearch_url'] = 'https://elasticsearch.login.gov.internal:9200'
default['elk']['logstash']['xpack_monitoring_elasticsearch_ssl_ca'] = '/etc/elasticsearch/root-ca.pem'

default['elk']['elastalert']['version'] = 'v0.2.4'
default['elk']['elastalert']['logvolumethresholds'] = {
  'logstash' => 30000,
  'cloudtrail' => 5000,
  'cloudwatch' => 2300
}
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

# For adding chef discovery cron job
default['elk']['chef_zero_client_configuration'] = '/etc/login.gov/repos/identity-devops/kitchen/chef-client.rb'

# change this per env to transition over to the account-specific logbuckets
default['elk']['aws_logging_bucket'] = "login-gov-logs-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
default['elk']['elb_logging_bucket'] = "login-gov.elb-logs.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
default['elk']['analytics_logging_bucket'] = "login-gov.reports.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"

# use this to turn off analytics logging support
default['elk']['analytics_logs'] = true
