# Elasticsearch Domain.  By default it is "es.login.gov.internal" for non auto
# scaled instances, and "elasticsearch.login.gov.internal" for auto scaled
# instances.  This is because the auto scaled instances are behind an ELB so
# that they can be dynamically created and destroyed, while the non auto scaled
# instances get explicitly added to a DNS record by terraform.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  default['es']['domain'] = "elasticsearch.login.gov.internal"
else
  default['es']['domain'] = "es.login.gov.internal"
end

# logfiles to watch
default['elk']['filebeat']['logfiles'] = [
  {'log' => '/srv/*/shared/log/*.log', 'type' => 'log', 'format' => 'text'},
  {'log' => '/srv/*/shared/log/events.log', 'type' => 'log', 'format' => 'json'},
  {'log' => '/srv/*/shared/log/production.log', 'type' => 'log', 'format' => 'text'},
  {'log' => '/opt/nginx/logs/*.log', 'type' => 'nginx-access', 'format' => 'text'},
  {'log' => '/var/log/syslog', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/log/auth.log', 'type' => 'syslog', 'format' => 'text'},
  {'log' => '/var/lib/docker/aufs/mnt/*/var/log/*/*.log', 'type' => 'syslog', 'format' => 'text'},
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

# get a modern version of java
default['java']['jdk_version'] = '8'

# remote files
default['elk']['kibanatarball'] = 'https://artifacts.elastic.co/downloads/kibana/kibana-5.1.2-linux-x86_64.tar.gz'
default['elk']['logstashdeb'] = 'https://artifacts.elastic.co/downloads/logstash/logstash-5.1.2.deb'
default['elk']['logstash-input-cloudwatch-logs-version'] = '0.10.3'
default['elk']['kibanalogtrailplugin'] = 'https://github.com/sivasamyk/logtrail/releases/download/0.1.7/logtrail-5.x-0.1.7.zip'


# users to allow into elk
default['elk']['users'] = [ ]

# set this so that we listen on 8443
default['apache']['listen'] = [8443]

default['elk']['elastalert']['version'] = 'master'
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

# For adding chef discovery cron job
default['elk']['chef_zero_client_configuration'] = '/etc/login.gov/repos/identity-devops/kitchen/chef-client.rb'
