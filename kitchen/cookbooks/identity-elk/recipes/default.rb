#
# Cookbook Name:: identity-elk
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

template '/etc/sysctl.d/elk.conf' do
  source 'sysctl_d_elk_conf.erb'
end

execute "sysctl -w vm.max_map_count=#{node.elk.vm_max_map_count}"

docker_service 'default' do
  action [:create, :start]
end

docker_image 'sebp/elk' do
  tag    'es501_l501_k501'
  action :pull
end

template '/root/30-s3output.conf' do
  source '30-s3output.conf.erb'
  variables ({
    :aws_region => Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['build_env']['TF_VAR_region']['value'],
    :aws_logging_bucket => "login-gov-#{node.chef_environment}-logs"
  })
end

template '/root/30-cloudtrailin.conf' do
  source '30-cloudtrailin.conf.erb'
  variables ({
    :aws_region => Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['build_env']['TF_VAR_region']['value'],
    :cloudtrail_logging_bucket => "login-gov-#{node.chef_environment}-cloudtrail"
  })
end

# create cert
acme_selfsigned "elk.login.gov.internal" do
  crt     "/etc/ssl/elk.login.gov.crt"
  key     "/etc/ssl/elk.login.gov.key"
  notifies :restart, 'service[apache2]'
  notifies :run, 'ruby_block[generate_ca_cert]', :immediately
end

# recreate cert using the key and using the CA:TRUE constraint
# (maybe fix this if/when the acme folks fix issue #55
ruby_block 'generate_ca_cert' do
  block do
    cn = 'elk.login.gov.internal'
    require 'openssl'
    key = OpenSSL::PKey::read(File.read('/etc/ssl/elk.login.gov.key'))
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.new([['CN', cn, OpenSSL::ASN1::UTF8STRING]])
    cert.not_before = Time.now
    cert.not_after = Time.now + 60 * 60 * 24 * node['acme']['renew']
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
    cert.add_extension ef.create_extension("subjectAltName", "DNS: #{node.cloud.public_ipv4}")
    cert.sign key, OpenSSL::Digest::SHA256.new
    f = File.new('/etc/ssl/elk.login.gov.cacrt','w')
    f.write(cert.to_pem)
    f.close()
  end
  action :nothing
end


# create a copy of the key that filebeat can read inside the container (ugly)
execute "openssl pkcs8 -topk8 -nocrypt -in /etc/ssl/elk.login.gov.key -out /etc/ssl/filebeat.login.gov.key"
file "/etc/ssl/filebeat.login.gov.key" do
  owner 992
  mode '0600'
end

# write pubkey into node
ruby_block 'store pubkey' do
  block do
    node.default['elk']['pubkey'] = File.read("/etc/ssl/elk.login.gov.cacrt")
  end
end

# run the container
docker_container 'elk' do
  repo 'sebp/elk'
  tag  'es501_l501_k501'
  port ['9200:9200','9300:9300','5044:5044','5601:5601']
  volumes [
    '/root/30-s3output.conf:/etc/logstash/conf.d/30-s3output.conf',
    '/etc/ssl/elk.login.gov.crt:/etc/pki/tls/certs/logstash-beats.crt',
    '/etc/ssl/filebeat.login.gov.key:/etc/pki/tls/private/logstash-beats.key',
    '/root/30-cloudtrailin.conf:/etc/logstash/conf.d/30-cloudtrailin.conf'
  ]
  tty true
end

docker_exec 'add plugins' do
  container 'elk'
  command ['/opt/logstash/bin/logstash-plugin', 'install', 'logstash-codec-cloudtrail']
end


# set up log retention using curator
# XXX will need to reconfigure this to point at elasticsearch cluster eventually
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

# set up ssl proxy frontend for kibana
include_recipe 'apache2'
include_recipe 'apache2::mod_ssl'
include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_http'
include_recipe 'apache2::mod_headers'
include_recipe 'apache2::mod_rewrite'
include_recipe 'apache2::mod_authn_core'
include_recipe 'apache2::mod_authn_file'
include_recipe 'apache2::mod_authz_core'
include_recipe 'apache2::mod_authz_user'
include_recipe 'apache2::mod_auth_basic'
template '/etc/apache2/sites-available/kibanaproxy.conf' do
  source 'kibanaproxy.conf.erb'
  notifies :restart, 'service[apache2]'
end
template '/etc/apache2/htpasswd' do
  source 'htpasswd.erb'
  variables ({
    :users => node['elk']['users']
  })
end
apache_site 'kibanaproxy'

