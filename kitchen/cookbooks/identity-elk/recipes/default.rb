#
# Cookbook Name:: identity-elk
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'java'

# create cert
mycert  = '/etc/logstash/elk.login.gov.crt'
mykey   = '/etc/logstash/elk.login.gov.key'
mycacrt = '/etc/logstash/elk.login.gov.cacrt'
mypkcs8 = '/etc/logstash/elk.login.gov.key.pkcs8'

directory '/etc/logstash'

acme_selfsigned "elk.login.gov.internal" do
  crt     mycert
  key     mykey
  notifies :restart, 'service[apache2]'
  notifies :run, 'ruby_block[generate_ca_cert]', :immediately
end

# recreate cert using the key and using the CA:TRUE constraint
# (maybe fix this if/when the acme folks fix issue #55)
ruby_block 'generate_ca_cert' do
  block do
    cn = 'elk.login.gov.internal'
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
    cert.add_extension ef.create_extension("subjectAltName", "DNS: #{node.hostname}.login.gov.internal, DNS: elk.tf.login.gov, DNS: elk.login.gov.internal, IP: #{node.cloud.public_ipv4}, IP: #{node.ipaddress}")
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
    node.default['elk']['pubkey'] = File.read("#{mycacrt}")
  end
end


# trust the other ES nodes
include_recipe 'identity-elk::trustesnodes'



# install logstash
remote_file '/usr/share/logstash.deb' do
  source node['elk']['logstashdeb']
end
dpkg_package 'logstash' do
  source '/usr/share/logstash.deb'
end

execute 'update-ca-certificates -f'
execute 'bin/logstash-plugin install logstash-codec-cloudtrail' do
  cwd '/usr/share/logstash'
  notifies :restart, 'runit_service[logstash]'
  not_if "bin/logstash-plugin list | grep logstash-codec-cloudtrail"
end

# XXX There seems to be no way to update to a specific version, so I hope this keeps working.  :-(
# XXX As of this moment (Mon Feb  6 16:41:46 PST 2017) , 3.1.1 is broken, and 3.1.2 is working.
execute 'bin/logstash-plugin update logstash-input-s3' do
  cwd '/usr/share/logstash'
end


# create a copy of the key/crt that filebeat can read
execute "openssl pkcs8 -topk8 -nocrypt -in #{mykey} -out #{mypkcs8}"
file "#{mypkcs8}" do
  owner 'logstash'
  mode '0600'
  notifies :restart, 'runit_service[logstash]'
end

file mycert do
  owner 'logstash'
end

template "/etc/logstash/conf.d/30-s3output.conf" do
  source '30-s3output.conf.erb'
  variables ({
    :aws_region => ConfigLoader.load_config(node, "build_env")["TF_VAR_region"],
    :aws_logging_bucket => "login-gov-#{node.chef_environment}-logs"
  })
  notifies :restart, 'runit_service[logstash]'
end

aws_account_id = `curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*(?=")'`.chomp

template "/etc/logstash/conf.d/30-cloudtrailin.conf" do
  source '30-cloudtrailin.conf.erb'
  variables ({
    :aws_region => ConfigLoader.load_config(node, "build_env")["TF_VAR_region"],
    :cloudtrail_logging_bucket => "login-gov-cloudtrail-#{aws_account_id}"
  })
  notifies :restart, 'runit_service[logstash]'
end

# dynamically slurp in all the ES nodes
esnodes = search(:node, "recipes:elasticsearch*es AND chef_environment:#{node.chef_environment}", :filter_result => { 'ipaddress' => [ 'ipaddress' ]})

template '/etc/logstash/logstash-template.json' do
  source 'logstash-template.json.erb'
  notifies :restart, 'runit_service[logstash]'
end

template '/etc/logstash/conf.d/30-ESoutput.conf' do
  source '30-ESoutput.conf.erb'
  variables ({
    #:hostips => esnodes.map{|h| "\"#{h['ipaddress']}\""}.sort.uniq.join(', ')
    :hostips => "\"es.login.gov.internal\""
  })
  notifies :restart, 'runit_service[logstash]'
end

template '/etc/logstash/conf.d/40-beats.conf' do
  source '40-beats.conf.erb'
  variables ({
    :mycrt => "#{mycacrt}",
    :mykey => "#{mypkcs8}"
  })
  notifies :restart, 'runit_service[logstash]'
end

directory '/etc/logstash/tmp' do
  owner 'logstash'
  mode '0700'
end

# turn off the non-sv service
execute 'service logstash stop || true'
execute 'update-rc.d -f logstash remove'

include_recipe 'runit'
runit_service 'logstash' do
  default_logger true
  sv_timeout 20
  options ({
    :home => '/usr/share/logstash',
    :max_heap => "#{(node['memory']['total'].to_i * 0.5).floor / 1024}M",
    :min_heap => "#{(node['memory']['total'].to_i * 0.2).floor / 1024}M",
    :gc_opts => '-XX:+UseParallelOldGC',
    :java_opts => '-Dio.netty.native.workdir=/etc/logstash/tmp',
    :tmpdir => '/var/tmp',
    :ipv4_only => false,
    :workers => 2,
    :debug => false,
    :user => 'logstash',
    :group => 'logstash'
  }.merge(params))
end


# install kibana (grr, package doesn't work right now)
user 'kibana' do
  system true
end

remote_file '/usr/share/kibana.tar.gz' do
  source node['elk']['kibanatarball']
end

kibanaextractdir = node['elk']['kibanatarball'].gsub(/https.*\/(.*).tar.gz/, '\1')
execute "tar zxpf kibana.tar.gz" do
  cwd '/usr/share'
  creates kibanaextractdir
end

link '/usr/share/kibana' do
  to "/usr/share/#{kibanaextractdir}"
end

directory '/usr/share/kibana/config'

execute 'chown -R kibana /usr/share/kibana/optimize /usr/share/kibana/data'

template '/usr/share/kibana/config/kibana.yml' do
  source 'kibana.yml.erb'
  notifies :restart, 'runit_service[kibana]'
end

execute "bin/kibana-plugin install #{node['elk']['kibanalogtrailplugin']}" do
  cwd '/usr/share/kibana'
  creates '/usr/share/kibana/plugins/logtrail/index.js'
end

template '/usr/share/kibana/plugins/logtrail/logtrail.json' do
  source 'logtrail.json.erb'
  notifies :restart, 'runit_service[kibana]'
end

runit_service 'kibana' do
  default_logger true
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
%w{ status autoindex userdir info dav dav_fs }.each do |m|
  apache_module m do
    enable false
  end
end

template '/etc/apache2/sites-available/kibanaproxy.conf' do
  source 'kibanaproxy.conf.erb'
  notifies :restart, 'service[apache2]'
end
template '/etc/apache2/htpasswd' do
  source 'htpasswd.erb'
  mode '0644'
  variables ({
    :users => node['elk']['users']
  })
end
apache_site 'kibanaproxy'

include_recipe 'identity-elk::filebeat'

# === set up elastalert ===
package 'python-pip'

# python cryptography build dependencies
package 'python-dev'
package 'libssl-dev'
package 'libffi-dev'

elastalertdir = '/usr/share/elastalert'
git elastalertdir do
  repository 'https://github.com/Yelp/elastalert.git'
  revision node['elk']['elastalertversion']
  action :sync
end
directory "#{elastalertdir}/rules.d"

execute 'pip install --upgrade six' do
  cwd elastalertdir
  # XXX This seems a bit fragile, but it'll probably work
  only_if 'pip list | grep "six .1.5"'
end
execute 'python setup.py install' do
  cwd elastalertdir
  creates '/usr/local/bin/elastalert'
end
execute 'pip install -r requirements.txt' do
  cwd elastalertdir
  not_if 'pip list | grep funcsigs'
end
execute 'pip install "elasticsearch>=5.0.0"' do
  cwd elastalertdir
  not_if 'pip list | egrep "^elasticsearch .5"'
end

template "#{elastalertdir}/config.yaml" do
  source 'elastalert_config.yaml.erb'
  notifies :restart, 'runit_service[elastalert]'
end

%w{invaliduser.yaml newsudo.yaml nologs.yaml failedlogins.yaml unknownip.yaml}.each do |t|
  template "#{elastalertdir}/rules.d/#{t}" do
    source "elastalert_#{t}.erb"
    variables ({
      :env => node.chef_environment,
      :emails => node['elk']['elastalert']['emails'],
      :webhook => ConfigLoader.load_config(node, "slackwebhook"),
      :slackchannel => ConfigLoader.load_config(node, "slackchannel")
    })
    notifies :restart, 'runit_service[elastalert]'
  end
end

user 'elastalert' do
  system true
end

runit_service 'elastalert' do
  default_logger true
end

# set up the stuff that slurps in the vpc flow logs
git '/usr/share/logstash-input-cloudwatch_logs' do
  repository 'https://github.com/lukewaite/logstash-input-cloudwatch-logs.git'
  revision "v#{node['elk']['logstash-input-cloudwatch-logs-version']}"
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/gem build logstash-input-cloudwatch_logs.gemspec" do
  cwd '/usr/share/logstash-input-cloudwatch_logs'
end

execute "bin/logstash-plugin install /usr/share/logstash-input-cloudwatch_logs/logstash-input-cloudwatch_logs-#{node['elk']['logstash-input-cloudwatch-logs-version']}.gem" do
  cwd '/usr/share/logstash'
  notifies :restart, 'runit_service[logstash]'
  not_if "bin/logstash-plugin list | grep logstash-input-cloudwatch_logs"
end

template "/etc/logstash/conf.d/50-cloudwatchin.conf" do
  source '50-cloudwatchin.conf.erb'
  variables ({
    :aws_region => ConfigLoader.load_config(node, "build_env")["TF_VAR_region"],
    :env => node.chef_environment
  })
  notifies :restart, 'runit_service[logstash]'
end
