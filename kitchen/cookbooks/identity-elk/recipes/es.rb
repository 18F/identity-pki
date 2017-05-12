#
# Cookbook Name:: identity-elk
# Recipe:: es
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'java'

directory '/etc/elasticsearch'

# XXX mount disk up
# /dev/sdg
#    path_data    "/var/lib/elasticsearch"


# install elasticsearch
elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
  type 'tarball' # type of install
  version "5.1.2"
end


# create keystore/truststore
include_recipe 'keytool'
storepass = 'EipbelbyamyotsOjHod2'
san = "san=dns:es.login.gov.internal,dns:#{node.name},dns:localhost,ip:#{node.ipaddress},ip:127.0.0.1,oid:1.2.3.4.5.5"

keytool_manage 'create keystore' do
  action :createstore
  keystore '/etc/elasticsearch/keystore.jks'
  keystore_alias node.ipaddress
  common_name 'es.login.gov.internal'
  org_unit node.chef_environment
  org 'login.gov'
  location 'Washington DC'
  country 'US'
  storepass storepass
  additional "-ext #{san}"
end

# generate a CA
sgdir = "#{Chef::Config[:file_cache_path]}/search-guard-ssl"
pkidir = sgdir + "/example-pki-scripts"
git sgdir do
  repository 'https://github.com/floragunncom/search-guard-ssl.git'
  checkout_branch '5.1.1'
end
execute "#{pkidir}/gen_root_ca.sh #{storepass} #{storepass}" do
  cwd pkidir
  creates 'ca/chain-ca.pem'
end

# export, sign, import cert
execute "keytool -certreq -alias #{node.ipaddress} -keystore /etc/elasticsearch/keystore.jks -file #{pkidir}/cacrt.csr -keypass #{storepass} -storepass #{storepass} -dname 'CN=es.login.gov.internal, OU=#{node.chef_environment}, O=login.gov, L=Washington DC, C=US' -ext #{san}" do
  creates pkidir + '/cacrt.csr'
end

execute "openssl ca -in #{pkidir}/cacrt.csr -notext -out /etc/elasticsearch/es.login.gov.crt -config etc/signing-ca.conf -extensions v3_req -batch -passin pass:#{storepass} -extensions server_ext" do
  creates '/etc/elasticsearch/es.login.gov.crt'
  cwd pkidir
end

execute "sed -i 's/\r//' /etc/elasticsearch/es.login.gov.crt"

keytool_manage "import my signed cert into keystore" do
  cert_alias node.ipaddress
  action :importcert
  file '/etc/elasticsearch/es.login.gov.crt'
  keystore "/etc/elasticsearch/keystore.jks"
  storepass storepass
end

# write cert and chain into node
ruby_block 'store cacrt' do
  block do
    node.default['elk']['espubkey'] = File.read('/etc/elasticsearch/es.login.gov.crt') + File.read("#{pkidir}/ca/chain-ca.pem")
  end
end

# dynamically slurp in all the other ES nodes and make sure we get ourselves in for sure.
esnodes = search(:node, "elk_espubkey:* AND chef_environment:#{node.chef_environment}", :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'crt' => ['elk','espubkey'], 'name' => ['name']})
esips = esnodes.map{|h| h['ipaddress']}.sort.uniq.join(', ')

# trust the other ES nodes
include_recipe 'identity-elk::trustesnodes'

esnodes.each do |h|
  keytool_manage "import #{h['ipaddress']} into truststore" do
    cert_alias h['ipaddress']
    action :importcert
    file "/etc/elasticsearch/es_#{h['name']}.crt"
    keystore '/etc/elasticsearch/truststore.jks'
    storepass storepass
    additional '-trustcacerts'
    only_if "test -s /etc/elasticsearch/es_#{h['name']}.crt"
  end
  keytool_manage "import #{h['name']} into truststore" do
    cert_alias h['name']
    action :importcert
    file "/etc/elasticsearch/es_#{h['name']}.crt"
    keystore '/etc/elasticsearch/truststore.jks'
    storepass storepass
    additional '-trustcacerts'
    only_if "test -s /etc/elasticsearch/es_#{h['name']}.crt"
  end
  keytool_manage "import my cert into truststore" do
    cert_alias "es.login.gov.internal"
    action :importcert
    file '/etc/elasticsearch/es.login.gov.crt'
    keystore "/etc/elasticsearch/truststore.jks"
    storepass storepass
    additional '-trustcacerts'
  end
end


elasticsearch_configure "elasticsearch" do
  configuration ({
    'discovery.zen.ping.unicast.hosts' => esips,
    'network.bind_host' => '0.0.0.0',
    'network.publish_host' => node[:ipaddress],
    'searchguard.ssl.transport.keystore_filepath' => '/etc/elasticsearch/keystore.jks',
    'searchguard.ssl.transport.keystore_password' => storepass,
    'searchguard.ssl.transport.truststore_filepath' => '/etc/elasticsearch/truststore.jks',
    'searchguard.ssl.transport.truststore_password' => storepass,
    'searchguard.ssl.transport.enforce_hostname_verification' => false,
    'searchguard.ssl.transport.resolve_hostname' => false,
    'searchguard.ssl.http.enabled' => true,
    'searchguard.ssl.http.keystore_filepath' => '/etc/elasticsearch/keystore.jks',
    'searchguard.ssl.http.keystore_password' => storepass,
    'searchguard.ssl.http.truststore_filepath' => '/etc/elasticsearch/truststore.jks',
    'searchguard.ssl.http.truststore_password' => storepass,
    'searchguard.authcz.admin_dn' => ["CN=es.login.gov.internal","CN=es.login.gov.internal, OU=#{node.chef_environment}, O=login.gov, L=Washington DC, C=US"]
  })
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

execute '/var/lib/dpkg/info/ca-certificates-java.postinst configure'

elasticsearch_plugin 'x-pack' do
  action :remove
end

directory '/etc/elasticsearch/sgadmin' do
  owner 'elasticsearch'
end

elasticsearch_plugin 'com.floragunn:search-guard-5:5.1.2-11' do
  plugin_name 'com.floragunn:search-guard-5:5.1.2-11'
  not_if "/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep search-guard-5"
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

file '/usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh' do
  mode '0755'
end


elasticsearch_service 'elasticsearch' do
  service_actions [:enable, :start]
end

# set up sgadmin stuff
%w{sg_action_groups.yml sg_config.yml sg_internal_users.yml sg_roles_mapping.yml sg_roles.yml}.each do |f|
  template "/etc/elasticsearch/sgadmin/#{f}"
end
execute "/usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh -ts /etc/elasticsearch/truststore.jks -tspass '#{storepass}' -ks /etc/elasticsearch/keystore.jks -kspass '#{storepass}' -cd /etc/elasticsearch/sgadmin/ -icl -nhnv" do
  ignore_failure true
end


# set up log retention using curator
include_recipe 'elasticsearch-curator'

node['elk']['indextypes'].each do |index|
  logretentionconfig = {
    'actions' => {
      1 => {
        'action' => "delete_indices",
        'description' => "Delete indices older than #{node['elk']['retentiondays']} days",
        'options' => {
          'ignore_empty_list' => true,
          'continue_if_exception' => true,
          'disable_action' => false
        },
        'filters' => [
          { 'filtertype' => 'pattern',
            'kind' => 'prefix',
            'value' => "#{index}-" },
          { 'filtertype' => 'age',
            'source' => 'creation_date',
            'direction' => 'older',
            'unit' => 'days',
            'unit_count' => node['elk']['retentiondays'] }
        ]
      }
    }
  }

  elasticsearch_curator_action "#{index}_retention" do
    config logretentionconfig
    minute '0'
    hour '2'
    action :create
  end
end

