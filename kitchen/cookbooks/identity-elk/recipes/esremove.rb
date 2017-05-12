# This recipe removes elasticsearch cert stuff so that you can start over.
# 

execute 'service elasticsearch stop'

# delete the certs on disk.
execute 'rm -rf /etc/elasticsearch/keystore.jks /etc/elasticsearch/truststore.jks /etc/elasticsearch/es* /var/chef/cache/search-guard-ssl/'

# delete the certs in chef
node.default['elk'].delete('espubkey')
node.save



