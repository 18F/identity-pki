# needed to make sure that elasticsearch can start up
default['elk']['vm_max_map_count'] = 524288

# config since filebeat seems not to handle ports directly
default['elk']['filebeat']['port'] = 5044

# logfiles to watch
default['elk']['filebeat']['logfiles'] = [
  {'log' => '/srv/*/shared/log/*.log', 'type' => 'log'},
  {'log' => '/opt/nginx/logs/*.log', 'type' => 'nginx-access'},
  {'log' => '/var/log/syslog', 'type' => 'syslog'},
  {'log' => '/var/log/auth.log', 'type' => 'syslog'},
  {'log' => '/var/lib/docker/aufs/mnt/*/var/log/*/*.log', 'type' => 'syslog'},
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

# set this so that we listen on 8443
default['apache']['listen'] = [8443]

# list of users that we allow in
#default['elk']['users'] = ['user1']

