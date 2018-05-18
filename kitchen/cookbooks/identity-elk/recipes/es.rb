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

# mount extra disk up if it's there
execute 'extend_disk' do
  command 'vgextend securefolders /dev/xvdg ; lvextend -l+100%FREE /dev/securefolders/variables ; resize2fs /dev/mapper/securefolders-variables'
  only_if 'lsblk /dev/xvdg'
  not_if  'pvdisplay | grep .dev.xvdg >/dev/null'
end


# install elasticsearch
elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
  type 'tarball' # type of install
  version "5.1.2"
end

# URL to reach the elasticsearch cluster.  In the pre-auto-scaled world this was
# a DNS record with one entry per elasticsearch host.  In the auto scaled world
# this is an ELB.
elasticsearch_domain = node.fetch("es").fetch("domain")

# create keystore/truststore
include_recipe 'keytool'
storepass = 'EipbelbyamyotsOjHod2'
san = "san=dns:#{elasticsearch_domain},dns:#{node.name},dns:localhost,ip:#{node.fetch('ipaddress')},ip:127.0.0.1,oid:1.2.3.4.5.5"

keytool_manage 'create keystore' do
  action :createstore
  keystore '/etc/elasticsearch/keystore.jks'
  keystore_alias node.fetch('ipaddress')
  common_name "#{elasticsearch_domain}"
  org_unit node.chef_environment
  org 'login.gov'
  location 'Washington DC'
  country 'US'
  storepass storepass
  additional "-ext #{san}"
end

keytool_manage 'create truststore' do
  action :createstore
  keystore '/etc/elasticsearch/truststore.jks'
  keystore_alias node.fetch('ipaddress')
  common_name "#{elasticsearch_domain}"
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
execute "keytool -certreq -alias #{node.fetch('ipaddress')} -keystore /etc/elasticsearch/keystore.jks -file #{pkidir}/cacrt.csr -keypass #{storepass} -storepass #{storepass} -dname 'CN=#{elasticsearch_domain}, OU=#{node.chef_environment}, O=login.gov, L=Washington DC, C=US' -ext #{san}" do
  creates pkidir + '/cacrt.csr'
end

execute "openssl ca -in #{pkidir}/cacrt.csr -notext -out /etc/elasticsearch/es.login.gov.crt -config etc/signing-ca.conf -extensions v3_req -batch -passin pass:#{storepass} -extensions server_ext" do
  creates '/etc/elasticsearch/es.login.gov.crt'
  cwd pkidir
end

execute "sed -i 's/\r//' /etc/elasticsearch/es.login.gov.crt"

keytool_manage "import my signed cert into keystore" do
  cert_alias node.fetch('ipaddress')
  action :importcert
  file '/etc/elasticsearch/es.login.gov.crt'
  keystore "/etc/elasticsearch/keystore.jks"
  storepass storepass
end

#############################
# Chef Server Compatibility #
#############################
#
# If we are running with a chef server, we can use the chef server's attributes
# to register this node's certificate.
#
# However, if we are running chef-zero locally as we do in test kitchen unit
# tests and bootstrapping ASGs, we need to rely on some other mechanism.  Our
# service_discovery cookbook abstracts out this service registration, and has
# libaries to publish certificates, so we can use that.
#
# We have to use it in a custom resource "publish_cert_and_chain" because of the
# chef compile versus converge time issue.  Things outside any resource run at
# compile time, and things in a resource run at converge time.  This is
# something we want to run at converge time wrapped in a resource because we
# have ruby code as well as other resources we need to run and the cert won't
# exist on disk until then.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  # Publish this node's certificate
  publish_cert_and_chain 'Publish the cert and chain of this ES node to s3.' do
    cert '/etc/elasticsearch/es.login.gov.crt'
    chain "#{pkidir}/ca/chain-ca.pem"
    cert_and_chain_path "/etc/elasticsearch/es.login.gov.pem"
    suffix "legacy-elasticsearch"
    owner "elasticsearch"
  end
else
  # write cert and chain into node
  ruby_block 'store cacrt' do
    block do
      node.default['elk']['espubkey'] = File.read('/etc/elasticsearch/es.login.gov.crt') + File.read("#{pkidir}/ca/chain-ca.pem")
    end
  end
end


# trust the other ES nodes
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  install_certificates 'Installing ES certificates to ca-certificates' do
    service_tag_key node['elk']['es_tag_key']
    service_tag_value node['elk']['es_tag_value']
    cert_user 'elasticsearch'
    cert_group 'elasticsearch'
    install_directory '/usr/local/share/ca-certificates'
    suffix 'legacy-elasticsearch'
    notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
  end

  install_certificates 'Installing ES certificates to /etc/elasticsearch' do
    service_tag_key node['elk']['es_tag_key']
    service_tag_value node['elk']['es_tag_value']
    cert_user 'elasticsearch'
    cert_group 'elasticsearch'
    install_directory '/etc/elasticsearch'
    suffix 'legacy-elasticsearch'
    notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
  end
  execute '/usr/sbin/update-ca-certificates' do
    action :nothing
  end
else
  include_recipe 'identity-elk::trustesnodes'
end

#############################
# Chef Server Compatibility #
#############################
#
# If we are running with a chef server, we can use the chef server's node search
# functionality to find other services.
#
# However, if we are running chef-zero locally as we do in test kitchen unit
# tests and bootstrapping ASGs, we need to rely on some other mechanism.  Our
# service_discovery cookbook abstracts out this service discovery and has
# libraries to fetch a list of services, so we can call that and then massage it
# to look like the old node list.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  services = ::Chef::Recipe::ServiceDiscovery.discover(node,
                                                       node.fetch('elk').fetch('es_tag_key'),
                                                       [node.fetch('elk').fetch('es_tag_value')])
  esnodes = services.map{|service| { "ipaddress" => service.fetch('instance').private_ip_address,
                                     "crt" => service.fetch("certificate"),
                                     "name" => service.fetch("hostname") } }
  esips = services.map{|service| service.fetch('instance').private_ip_address}.sort.uniq.join(', ')
else
  # dynamically slurp in all the other ES nodes and make sure we get ourselves in for sure.
  esnodes = search(:node, "elk_espubkey:* AND chef_environment:#{node.chef_environment}",
                   :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'crt' => ['elk','espubkey'], 'name' => ['name']})
  esips = esnodes.map{|h| h['ipaddress']}.sort.uniq.join(', ')
end

esnodes.each do |h|
  # import certs in from the new way
  keytool_manage "import #{h['ipaddress']} into truststore from legacy file" do
    cert_alias h['ipaddress']
    action :importcert
    file "/etc/elasticsearch/#{h['name']}-legacy-elasticsearch.crt"
    keystore '/etc/elasticsearch/truststore.jks'
    storepass storepass
    additional '-trustcacerts'
    only_if "test -s /etc/elasticsearch/#{h['name']}-legacy-elasticsearch.crt"
  end
  keytool_manage "import #{h['name']} into truststore from legacy file" do
    cert_alias h['name']
    action :importcert
    file "/etc/elasticsearch/#{h['name']}-legacy-elasticsearch.crt"
    keystore '/etc/elasticsearch/truststore.jks'
    storepass storepass
    additional '-trustcacerts'
    only_if "test -s /etc/elasticsearch/#{h['name']}-legacy-elasticsearch.crt"
  end

  # import certs the chef way
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
end

# I think this is necessary for searchguard, but I'm not completely sure since
# this node should discover itself and install its own certificate that way.
# Searchguard needs to have the certificate specified in
# 'searchguard.authcz.admin_dn' trusted, but I don't know how it maps that dn to
# the truststore alias internally.
keytool_manage "import my cert into truststore" do
  cert_alias "#{elasticsearch_domain}"
  action :importcert
  file '/etc/elasticsearch/es.login.gov.crt'
  keystore "/etc/elasticsearch/truststore.jks"
  storepass storepass
  additional '-trustcacerts'
end

# Elasticsearch now requires this value at a minimum
template "/etc/sysctl.d/99-chef-vm.max_map_count.conf" do
  source 'sysctl_d_elk_conf.erb'
  variables ({
    :vm_max_map_count => 262144
  })
end
execute "Set vm_max_map_count to 262144 in sysctl" do
  command "sysctl -p /etc/sysctl.d/99-chef-vm.max_map_count.conf"
end

# set the minimum number of master-eligible nodes to prevent data loss, see:
# https://www.elastic.co/guide/en/elasticsearch/reference/6.2/discovery-settings.html#minimum_master_nodes
min_masters_count = (esnodes.count / 2.to_f).floor + 1

elasticsearch_configure "elasticsearch" do
  configuration ({
    'discovery.zen.minimum_master_nodes' => min_masters_count,
    'discovery.zen.ping.unicast.hosts' => esips,
    'network.bind_host' => '0.0.0.0',
    'network.publish_host' => node.fetch('ipaddress'),
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
    'searchguard.authcz.admin_dn' => ["CN=#{elasticsearch_domain}","CN=#{elasticsearch_domain}, OU=#{node.chef_environment}, O=login.gov, L=Washington DC, C=US"]
  })
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

execute "wait for elasticsearch to start up without searchguard" do
  action :nothing
  command "wget -O - --no-check-certificate --server-response https://localhost:9200/ 2>&1 | egrep \"HTTP/1.1 (200|503)\""
  # TODO: The above command returns successfully even if search guard isn't
  # fully initialized.  Figure out how to make both the bootstrap and the
  # restart work with this check (because on bootstrap there is not search guard
  # at all).
  #command "curl --insecure https://localhost:9200 | grep \"cluster_name\""
  retries 10
  retry_delay 10
  subscribes :run, 'elasticsearch_service[elasticsearch]', :immediately
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

# This will be true if the instance is auto scaled.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  cron 'rerun elasticsearch setup every 15 minutes' do
    action :create
    minute '0,15,30,45'
    command "cat #{node.fetch('elk').fetch('chef_zero_client_configuration')} >/dev/null && chef-client --local-mode -c #{node.fetch('elk').fetch('chef_zero_client_configuration')} -o 'role[elasticsearch_discovery]' 2>&1 >> /var/log/elasticsearch/discovery.log"
  end
end
