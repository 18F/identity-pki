include_recipe 'java'

directory '/etc/elasticsearch'

# mount extra disk up if it's there
execute 'extend_disk' do
  command 'vgextend securefolders /dev/xvdg ; lvextend -l+100%FREE /dev/securefolders/variables ; resize2fs /dev/mapper/securefolders-variables'
  only_if 'lsblk /dev/xvdg'
  not_if  'pvdisplay | grep .dev.xvdg >/dev/null'
end

# format and mount the local nvme drive if available
execute 'format and mount nvme drive' do
  command 'mkfs.ext4 /dev/nvme0n1; mkdir -p /var/lib/elasticsearch ; mount /dev/nvme0n1 /var/lib/elasticsearch/'
  only_if 'lsblk /dev/nvme0n1'
  not_if  'mount -l | grep .dev.nvme0n1 >/dev/null'
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

services = ::Chef::Recipe::ServiceDiscovery.discover(
  node,
  node.fetch('elk').fetch('es_tag_key'),
  [node.fetch('elk').fetch('es_tag_value')]
)

esnodes = services.map{|service| {
  "ipaddress" => service.fetch('instance').private_ip_address,
  "crt" => service.fetch("certificate"),
  "name" => service.fetch("hostname") } }

esips = services.map{|service| service.fetch('instance').private_ip_address}.sort.uniq.join(', ')

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
    'searchguard.ssl.transport.pemcert_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.pem",
    'searchguard.ssl.transport.pemkey_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.key",
    'searchguard.ssl.transport.pemkey_password' => 'changeit',
    'searchguard.ssl.transport.pemtrustedcas_filepath' => "/etc/elasticsearch/root-ca.pem",
    'searchguard.ssl.transport.enforce_hostname_verification' => false,
    'searchguard.ssl.transport.resolve_hostname' => false,
    'searchguard.ssl.http.enabled' => true,
    'searchguard.ssl.http.pemcert_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.pem",
    'searchguard.ssl.http.pemkey_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.key",
    'searchguard.ssl.http.pemkey_password' => 'changeit',
    'searchguard.ssl.http.pemtrustedcas_filepath' => "/etc/elasticsearch/root-ca.pem",
    'searchguard.nodes_dn' => ["CN=#{elasticsearch_domain},OU=#{node.chef_environment},O=login.gov,L=Washington\\, DC,C=US"],
    'searchguard.authcz.admin_dn' => ["CN=admin.login.gov.internal,OU=#{node.chef_environment},O=login.gov,L=Washington\\, DC,C=US"]
  })
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

elasticsearch_plugin 'x-pack' do
  action :remove
end

# install search guard plugin
directory '/etc/elasticsearch/sgadmin' do
  owner 'elasticsearch'
end

elasticsearch_plugin 'com.floragunn:search-guard-5:5.1.2-15' do
  plugin_name 'com.floragunn:search-guard-5:5.1.2-15'
  not_if "/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep search-guard-5"
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

# Install SearchGuard TLS Tool
# https://github.com/floragunncom/search-guard-tlstool
# https://search-guard.com/generating-certificates-tls-tool/
remote_file '/usr/share/elasticsearch/plugins/search-guard-5/search-guard-tlstool-1.5.tar.gz' do
  checksum '97efc3cbc560a99e59bfdab3d896749a124d1945ce9c92d40bbfdbb10568aa70'
  source 'https://search.maven.org/remotecontent?filepath=com/floragunn/search-guard-tlstool/1.5/search-guard-tlstool-1.5.tar.gz'
end

execute 'extract search-guard-tlstool-1.5.tar.gz' do
  command 'tar xzvf search-guard-tlstool-1.5.tar.gz'
  cwd '/usr/share/elasticsearch/plugins/search-guard-5'
end

execute 'make SGtlsTool scripts executable' do 
  command 'chmod +x tools/*'
  cwd '/usr/share/elasticsearch/plugins/search-guard-5'
end

# add login.gov specific configuration
template '/usr/share/elasticsearch/plugins/search-guard-5/config/login.gov.yml' do
  source 'search-guard-ssl-login.gov.yml.erb'
end

# NOTE: redo using service discovery cookbook helpers
# Download CA and intermediate key pairs from s3 bucket if they exist
require 'aws-sdk'
aws_account_id = AwsMetadata.get_aws_account_id
s3_cert_url = "s3://login-gov.internal-certs.#{aws_account_id}-us-west-2/#{node.chef_environment}/elasticsearch/"

ca_file_list = %w(root-ca.key root-ca.pem root-ca.readme signing-ca.key signing-ca.pem issuer.pem)

ca_file_list.each do |f|
  execute 'download CA key pairs' do
    command "aws s3 cp --recursive #{s3_cert_url}#{f} /etc/elasticsearch"
    not_if { ::File.exist?("/etc/elasticsearch/#{f}") }
  end
end

# generate key pairs if they do not already exist
execute 'generate CA, intermediate, node, admin, and user key pairs' do
  command './tools/sgtlstool.sh -c config/login.gov.yml -ca -crt'
  cwd '/usr/share/elasticsearch/plugins/search-guard-5'
  not_if { ::File.exist?('/etc/elasticsearch/root-ca.pem') }
end

aws_s3_options = "--sse aws:kms --recursive --exclude '*' --include 'root-ca*' --include 'signing-ca*' --include 'issuer.pem'"
execute 'upload CA, intermediate, admin, and user key pairs to s3 bucket' do
  command "aws s3 cp #{aws_s3_options} /usr/share/elasticsearch/plugins/search-guard-5/out #{s3_cert_url}"
  only_if { ::File.exist?('/usr/share/elasticsearch/plugins/search-guard-5/out/root-ca.key') }
end

# Or generate a new node key pair if the root and intermediate key pairs have already been created
execute 'generate node key pair' do
  command './tools/sgtlstool.sh -c config/login.gov.yml -crt -t /etc/elasticsearch'
  cwd '/usr/share/elasticsearch/plugins/search-guard-5'
  only_if { ::File.exist?('/etc/elasticsearch/root-ca.pem') }
  not_if { ::File.exist?("/etc/elasticsearch/#{node.fetch('ipaddress')}.pem") }
end

# start elasticsearch
elasticsearch_service 'elasticsearch' do
  service_actions [:enable, :start]
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

# set up sgadmin stuff
%w{sg_action_groups.yml sg_config.yml sg_internal_users.yml sg_roles_mapping.yml sg_roles.yml}.each do |f|
  template "/etc/elasticsearch/sgadmin/#{f}"
end

# Shave a yak so that we can use the older version of sgadmin that doesn't support pem format

# create issuer cert
execute "cat root-ca.pem signing-ca.pem > issuer.pem" do
  cwd '/etc/elasticsearch'
end

execute 'convert PEM formatted keypair to p12' do
  command "openssl pkcs12 \
    -export \
    -CAfile issuer.pem \
    -chain \
    -in admin.pem \
    -inkey admin.key \
    -name admin \
    -out admin.p12 \
    -passin pass:changeit \
    -passout pass:changeit"
  cwd '/etc/elasticsearch'
end

execute 'create jks keystore with admin keys' do
  command "keytool \
    -importkeystore \
    -destkeystore admin.jks \
    -deststorepass changeit \
    -noprompt \
    -srckeystore admin.p12 \
    -srcstorepass changeit"
  cwd '/etc/elasticsearch'
end

execute 'import root-ca into jks truststore' do
  command "keytool \
    -importcert \
    -file /etc/elasticsearch/root-ca.pem \
    -keystore /etc/elasticsearch/truststore.jks \
    -noprompt \
    -storepass changeit"
  cwd '/etc/elasticsearch'
  not_if { ::File.exist?('/etc/elasticsearch/truststore.jks') }
end

execute 'run sgadmin' do
  command "/usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh \
    -cd /etc/elasticsearch/sgadmin/ \
    -icl \
    -ks admin.jks \
    -kspass changeit \
    -nhnv \
    -ts /etc/elasticsearch/truststore.jks \
    -tspass changeit"
  cwd '/etc/elasticsearch'
end

# Note: use this format of config for sgadmin once we upgrade to sg 5.6
# execute "/usr/share/elasticsearch/plugins/search-guard-5/tools/sgadmin.sh \
#    -cd /etc/elasticsearch/sgadmin/ \
#    -cacert /etc/elasticsearch/root-ca.pem \
#    -cert /etc/elasticsearch/admin.pem \
#    -key /etc/elasticsearch/admin.key  \
#    -keypass EipbelbyamyotsOjHod2 \
#    -nhnv
#    -icl"

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

cron 'rerun elasticsearch setup every 15 minutes' do
  action :create
  minute '0,15,30,45'
  command "cat #{node.fetch('elk').fetch('chef_zero_client_configuration')} >/dev/null && chef-client --local-mode -c #{node.fetch('elk').fetch('chef_zero_client_configuration')} -o 'role[elasticsearch_discovery]' 2>&1 >> /var/log/elasticsearch/discovery.log"
end
