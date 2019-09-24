# configure the java repo
# the java receipe will fail to setup the repo since we are
# using a proxy server
apt_repository 'openjdk-r-ppa' do
  uri "ppa:openjdk-r"
  distribution node.fetch('lsb').fetch('codename')
  key_proxy node.fetch('login_dot_gov').fetch('http_proxy')
end

include_recipe 'java'

# add a script to help format and mount the nvme drive if available
cookbook_file '/usr/local/sbin/format_nvme' do
  mode '0755'
end

# don't run if a drive is already mounted to the elasticsearch data path
execute '/usr/local/sbin/format_nvme' do
  not_if  'mount -l | grep elasticsearch >/dev/null'
end

# install elasticsearch
elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
  type 'tarball' # type of install
  version "7.3.1"
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
    'searchguard.ssl.transport.pemkey_password' => 'not-a-secret',
    'searchguard.ssl.transport.pemtrustedcas_filepath' => "/etc/elasticsearch/root-ca.pem",
    'searchguard.ssl.transport.enforce_hostname_verification' => false,
    'searchguard.ssl.transport.resolve_hostname' => false,
    'searchguard.ssl.http.enabled' => true,
    'searchguard.ssl.http.pemcert_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.pem",
    'searchguard.ssl.http.pemkey_filepath' => "/etc/elasticsearch/#{node.fetch('ipaddress')}.key",
    'searchguard.ssl.http.pemkey_password' => 'not-a-secret',
    'searchguard.ssl.http.pemtrustedcas_filepath' => "/etc/elasticsearch/root-ca.pem",
    'searchguard.nodes_dn' => ["CN=#{elasticsearch_domain},OU=#{node.chef_environment},O=login.gov,L=Washington\\, DC,C=US"],
    'searchguard.authcz.admin_dn' => ["CN=admin.login.gov.internal,OU=#{node.chef_environment},O=login.gov,L=Washington\\, DC,C=US"],
    'xpack.monitoring.collection.enabled' => true,
    'xpack.monitoring.history.duration' => "30d",
    'xpack.security.enabled' => false
  })
  logging({:"action" => 'INFO'})

  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

link '/usr/share/elasticsearch/config' do
  to '/etc/elasticsearch'
end

elasticsearch_plugin 'x-pack' do
  action :remove
end

# install search guard plugin
directory '/etc/elasticsearch/sgadmin' do
  owner 'elasticsearch'
end

aws_account_id = AwsMetadata.get_aws_account_id

execute 'download SearchGuard installer' do
  command 'aws s3 cp s3://login-gov-elasticsearch-#{node.chef_environment}.#{aws_account_id}-us-west-2/search-guard-7-7.3.1-36.1.0.zip /tmp/'
end

elasticsearch_plugin 'com.floragunn:search-guard-7:7.3.1-36.1.0' do
  plugin_name 'com.floragunn:search-guard-7:7.3.1-36.1.0'
  # The documentation says this is true by default, but the code disagrees.
  # https://github.com/elastic/cookbook-elasticsearch/issues/663
  chef_proxy true
  options '-b'
  url 'file:/tmp/search-guard-7-7.3.1-36.1.0.zip'
  not_if "/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep search-guard-7"
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

# Install SearchGuard TLS Tool
# https://github.com/floragunncom/search-guard-tlstool
# https://search-guard.com/generating-certificates-tls-tool/
remote_file '/usr/share/elasticsearch/plugins/search-guard-7/search-guard-tlstool-1.7.tar.gz' do
  checksum '284492779edf037348375994a0f320cc1425bda149d56c3db0031014241e7110'
  source 'https://search.maven.org/remotecontent?filepath=com/floragunn/search-guard-tlstool/1.7/search-guard-tlstool-1.7.tar.gz'
end

execute 'extract search-guard-tlstool-1.7.tar.gz' do
  command 'tar xzvf search-guard-tlstool-1.7.tar.gz'
  cwd '/usr/share/elasticsearch/plugins/search-guard-7'
end

execute 'make SGtlsTool scripts executable' do 
  command 'chmod +x tools/*'
  cwd '/usr/share/elasticsearch/plugins/search-guard-7'
end

# add login.gov specific configuration
template '/usr/share/elasticsearch/plugins/search-guard-7/config/login.gov.yml' do
  source 'search-guard-ssl-login.gov.yml.erb'
end

################################
# ELK Key Sharing Disclaimer
#
# We understand that sharing the CA/Signing keys in such a manner has inherent vulnererabilities and
# is in effect pseudo TLS. That said, this is not significantly different from the previous scheme,
# it is contained within a VPC, and it is only used for intra elasticsearch/logstash communications.
# By design our logs do not contain sensitive data.
#
# We will revisit this area once we look further into AWS Certificate Manager, AWS Secrets Manager,
# Vault/Console, and other options
#
# For further context see discussion here:
# https://github.com/18F/identity-devops/pull/990#issuecomment-404663498
################################

# NOTE: refactor using service discovery cookbook helpers
# Download CA and intermediate key pairs from s3 bucket if they exist
s3_cert_url = "s3://login-gov.internal-certs.#{aws_account_id}-us-west-2/#{node.chef_environment}/elasticsearch/"

file_list = %w(root-ca.key root-ca.pem signing-ca.key signing-ca.pem issuer.pem admin.jks)

file_list.each do |f|
  execute "download #{f} from s3" do
    command "aws s3 cp #{s3_cert_url}#{f} /etc/elasticsearch"
    not_if { ::File.exist?("/etc/elasticsearch/#{f}") }
    ignore_failure true
  end
end

# generate key pairs if they do not already exist
execute 'generate CA, intermediate, node, admin, and user key pairs' do
  command './tools/sgtlstool.sh -c config/login.gov.yml -t /etc/elasticsearch -ca -crt'
  cwd '/usr/share/elasticsearch/plugins/search-guard-6'
  not_if { ::File.exist?('/etc/elasticsearch/root-ca.pem') }
end

# create issuer cert
execute "cat root-ca.pem signing-ca.pem > issuer.pem" do
  cwd '/etc/elasticsearch'
end

aws_s3_options = "--sse aws:kms --recursive --exclude '*' --include 'admin.*' --include 'issuer.pem' --include 'root-ca*' --include 'signing-ca*'"
execute 'upload CA, intermediate, admin, and user key pairs to s3 bucket' do
  command "aws s3 cp #{aws_s3_options} /etc/elasticsearch #{s3_cert_url}"
  only_if { ::File.exist?('/etc/elasticsearch/client-certificates.readme') }
end

# Or generate a new node key pair if the root and intermediate key pairs have already been created
execute 'generate node key pair' do
  command './tools/sgtlstool.sh -c config/login.gov.yml -crt -t /etc/elasticsearch'
  cwd '/usr/share/elasticsearch/plugins/search-guard-7'
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
%w{sg_action_groups.yml sg_config.yml sg_internal_users.yml sg_roles_mapping.yml sg_roles.yml sg_tenants.yml}.each do |f|
  cookbook_file "/etc/elasticsearch/sgadmin/#{f}"
end

# Shave a yak so that we can use the older version of sgadmin that doesn't support pem format
execute 'convert PEM formatted keypair to p12' do
  command "openssl pkcs12 \
    -export \
    -CAfile issuer.pem \
    -chain \
    -in admin.pem \
    -inkey admin.key \
    -name admin \
    -out admin.p12 \
    -passin pass:not-a-secret \
    -passout pass:not-a-secret"
  cwd '/etc/elasticsearch'
end

execute 'create jks keystore with admin keys' do
  command "keytool \
    -importkeystore \
    -destkeystore admin.jks \
    -deststorepass not-a-secret \
    -noprompt \
    -srckeystore admin.p12 \
    -srcstorepass not-a-secret"
  cwd '/etc/elasticsearch'
end

execute 'import root-ca into jks truststore' do
  command "keytool \
    -importcert \
    -alias root.login.gov.internal \
    -file /etc/elasticsearch/root-ca.pem \
    -keystore /etc/elasticsearch/truststore.jks \
    -noprompt \
    -storepass not-a-secret"
  cwd '/etc/elasticsearch'
  not_if { ::File.exist?('/etc/elasticsearch/truststore.jks') }
end

execute 'run sgadmin' do
  command "/usr/share/elasticsearch/plugins/search-guard-7/tools/sgadmin.sh \
    -cd /etc/elasticsearch/sgadmin/ \
    -ks admin.jks \
    -kspass not-a-secret \
    -nhnv \
    -ts /etc/elasticsearch/truststore.jks \
    -tspass not-a-secret"
  cwd '/etc/elasticsearch'
end

execute "/usr/share/elasticsearch/plugins/search-guard-7/tools/sgadmin.sh \
   -cd /etc/elasticsearch/sgadmin/ \
   -cacert /etc/elasticsearch/root-ca.pem \
   -cert /etc/elasticsearch/admin.pem \
   -key /etc/elasticsearch/admin.key  \
   -keypass not-a-secret \
   -nhnv"

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
  command "flock -n /tmp/es_setup.lock -c \"cat #{node.fetch('elk').fetch('chef_zero_client_configuration')} >/dev/null && chef-client --local-mode -c #{node.fetch('elk').fetch('chef_zero_client_configuration')} -o 'role[elasticsearch_discovery]' 2>&1 >> /var/log/elasticsearch/discovery.log\""
end

use_common_license = node.chef_environment == 'prod' ? false : true

file '/etc/xpack_license' do
  content ConfigLoader.load_config(node, 'xpack_license', common: use_common_license)
end

cookbook_file '/usr/local/bin/xpack_license_updater' do
  mode '0755'
end

execute '/usr/local/bin/xpack_license_updater'
