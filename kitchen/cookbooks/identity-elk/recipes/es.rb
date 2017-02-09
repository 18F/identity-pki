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

# create cert
mycert  = '/etc/elasticsearch/es.login.gov.crt'
mykey   = '/etc/elasticsearch/es.login.gov.key'
mycacrt = '/etc/elasticsearch/es.login.gov.cacrt'

acme_selfsigned "es.login.gov.internal" do
  crt     mycert
  key     mykey
  notifies :run, 'ruby_block[generate_ca_cert]', :immediately
end

# recreate cert using the key and using the CA:TRUE constraint
# (maybe fix this if/when the acme folks fix issue #55
ruby_block 'generate_ca_cert' do
  block do
    cn = 'es.login.gov.internal'
    require 'openssl'
    key = OpenSSL::PKey::read(File.read(mykey))
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.new([['CN', cn, OpenSSL::ASN1::UTF8STRING]])
    cert.not_before = Time.now
    cert.not_after = Time.now + 60 * 600 * 24 * node['acme']['renew']
    cert.public_key = key.public_key
    cert.serial = 0x0
    cert.version = 2
    
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension('basicConstraints', 'CA:TRUE', true),
      ef.create_extension('subjectKeyIdentifier', 'hash'),
    ]
    cert.add_extension ef.create_extension("subjectAltName", "DNS: #{node.hostname}.login.gov.internal, DNS: es.login.gov.internal, IP: #{node.cloud.public_ipv4}, IP: #{node.ipaddress}")
    cert.sign key, OpenSSL::Digest::SHA256.new
    f = File.new("#{mycacrt}",'w')
    f.write(cert.to_pem)
    f.close()
  end
  action :nothing
end

# write pubkey into node
ruby_block 'store pubkey' do
  block do
    node.default['elk']['espubkey'] = File.read("#{mycacrt}")
  end
end

# XXX mount disk up
# /dev/sdg
#    path_data    "/var/lib/elasticsearch"



# install elasticsearch
elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
  type 'tarball' # type of install
  version "5.1.2"
end

[mykey, mycert, mycacrt].each do |f|
  file f do
    owner 'elasticsearch'
  end
end

# dynamically slurp in all the other ES nodes and make sure we get ourselves in for sure.
esnodes = search(:node, "elk_espubkey:* AND chef_environment:#{node.chef_environment}", :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'crt' => ['elk','espubkey'], 'name' => ['name']})

# trust the other ES nodes
include_recipe 'identity-elk::trustesnodes'

esips = esnodes.map{|h| h['ipaddress']}.sort.uniq.join(', ')
escerts = esnodes.map{|h| "/etc/elasticsearch/es_#{h['name']}.crt"}.sort.uniq
elasticsearch_configure "elasticsearch" do
  configuration ({
    'discovery.zen.ping.unicast.hosts' => esips,
    'network.bind_host' => '0.0.0.0',
    'network.publish_host' => node[:ipaddress],
    'xpack.security.authc' => {
      'anonymous' => {
        'username' => 'anonymous_user',
        'roles' => 'superuser',
        'authz_exception' => true
      }
    },
    'xpack.ssl.key' => mykey,
    'xpack.ssl.certificate' => mycacrt,
    'xpack.security.transport.ssl.enabled' => true,
    'xpack.security.http.ssl.enabled' => true,
    'xpack.ssl.certificate_authorities' => escerts
  })
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

execute '/var/lib/dpkg/info/ca-certificates-java.postinst configure'

elasticsearch_plugin 'x-pack' do
  notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end

elasticsearch_service 'elasticsearch' do
  service_actions [:enable, :start]
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

# turn off audit logging of elasticsearch activities in the elasticsearch dir
# (this totally spams the logs)
# XXX remove this as soon as we get this into our base AMI and it is deployed everywhere!
#auditctl -A exit,never -F dir=/var/lib/elasticsearch/nodes -F uid=elasticsearch
ruby_block 'removeESauditlogs' do
  block do
    fe = Chef::Util::FileEdit.new('/etc/audit/audit.rules')
    fe.insert_line_after_match(/^-f 1$/, '-a exit,never -F dir=/var/lib/elasticsearch/nodes -F uid=elasticsearch')
    fe.write_file
  end
  not_if { File.readlines('/etc/audit/audit.rules').grep(/dir=\/var\/lib\/elasticsearch\/nodes -F uid=elasticsearch/).any? }
end

