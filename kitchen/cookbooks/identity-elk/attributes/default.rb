# logfiles to watch
default['elk']['filebeat']['logfiles'] = [
  {'log' => '/srv/*/shared/log/*.log', 'type' => 'log'},
  {'log' => '/opt/nginx/logs/*.log', 'type' => 'nginx-access'},
  {'log' => '/var/log/syslog', 'type' => 'syslog'},
  {'log' => '/var/log/auth.log', 'type' => 'syslog'},
  {'log' => '/var/lib/docker/aufs/mnt/*/var/log/*/*.log', 'type' => 'syslog'},
  {'log' => '/var/log/*/current', 'type' => 'log'},
  {'log' => '/var/log/*/*.log', 'type' => 'syslog'}
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
default['elk']['logstash-input-cloudwatch-logs-version'] = '0.9.3'


# users to allow into elk
default['elk']['users'] = [
  'astone',
  'jgrevich',
  'jpmugizi',
  'monfresh',
  'mzia',
  'pkarman',
  'tblack',
  'tspencer',
  'zmargolis'
]

# set this so that we listen on 8443
default['apache']['listen'] = [8443]

default['elk']['elastalert']['version'] = 'master'
# If the list of emails is empty, then do not email.
default['elk']['elastalert']['emails'] = []
# If the webhook is set to nil, then do not do slack alerting.
default['elk']['elastalert']['slackwebhook'] = nil
default['elk']['elastalert']['slackchannel'] = '#identity-events'

# curator config
default['elasticsearch-curator']['config'] = {
  'client' => {
    'hosts' => ['es.login.gov.internal'],
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

