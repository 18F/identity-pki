#
# Cookbook Name:: identity-elk
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# URL to reach the elasticsearch cluster.  In the pre-auto-scaled world this was
# a DNS record with one entry per elasticsearch host.  In the auto scaled world
# this is an ELB.
elasticsearch_domain = node.fetch("es").fetch("domain")

include_recipe 'java'

# create cert
mycert  = '/etc/logstash/elk.login.gov.crt'
mykey   = '/etc/logstash/elk.login.gov.key'
mycacrt = '/etc/logstash/elk.login.gov.cacrt'
mypkcs8 = '/etc/logstash/elk.login.gov.key.pkcs8'

directory '/etc/logstash'

execute 'generate_elk_key' do
  command "openssl genrsa -out '#{mykey}' 2048"
  umask '0066'
  creates mykey

  notifies :run, 'ruby_block[generate_elk_cert]', :immediately
end

ruby_block 'generate_elk_cert' do
  block do
    require 'openssl'
    subject = OpenSSL::X509::Name.new([
      ['CN', 'elk.login.gov.internal', OpenSSL::ASN1::UTF8STRING],
      ['OU', node.chef_environment, OpenSSL::ASN1::UTF8STRING],
    ])
    key = OpenSSL::PKey::read(File.read(mykey))
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = subject
    cert.not_before = Time.now
    cert.not_after = Time.now + 60 * 600 * 24 * node['acme']['renew']
    cert.public_key = key.public_key
    cert.serial = Random.rand(2**64-1) + 1
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension('basicConstraints', 'CA:FALSE', true),
      ef.create_extension('subjectKeyIdentifier', 'hash'),
    ]
    cert.add_extension ef.create_extension("subjectAltName", "DNS: logstash.login.gov.internal, DNS: #{node.fetch('hostname')}.login.gov.internal, DNS: #{node.fetch('fqdn')}")
    cert.sign key, OpenSSL::Digest::SHA256.new
    f = File.new("#{mycert}",'w')
    f.write(cert.to_pem)
    f.close()
  end

  not_if { File.exist?(mycert) && File.stat(mycert).mtime >= File.stat(mykey).mtime }

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
    cert.serial = Random.rand(2**64-1) + 1
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension('basicConstraints', 'CA:TRUE', true),
      ef.create_extension('subjectKeyIdentifier', 'hash'),
    ]
    cert.add_extension ef.create_extension("subjectAltName", "DNS: #{node.fetch('hostname')}.login.gov.internal, DNS: logstash.login.gov.internal, DNS: elk.tf.login.gov, DNS: elk.login.gov.internal, IP: #{node.fetch('cloud').fetch('public_ipv4')}, IP: #{node.fetch('ipaddress')}")
    cert.sign key, OpenSSL::Digest::SHA256.new
    f = File.new("#{mycacrt}",'w')
    f.write(cert.to_pem)
    f.close()
  end
  action :nothing
end

# If we were running with a chef server, we could use the chef server's
# attributes to register this node's certificate.
#
# However, we are running chef-zero locally, so we need to rely on some other
# mechanism.  Our service_discovery cookbook abstracts out this service
# registration, and has libaries to publish certificates, so we can use that.
#
# We have to use it in a custom resource "publish_cert_and_chain" because of the
# chef compile versus converge time issue.  Things outside any resource run at
# compile time, and things in a resource run at converge time.  This is
# something we want to run at converge time wrapped in a resource because we
# have ruby code as well as other resources we need to run and the cert won't
# exist on disk until then.
#
# TODO: Much of this is for backwards compatibility.  Consolidate using the
# default instance certificates generated by the instance_certificate library,
# which are published automatically.
# Publish this node's certificate
publish_cert_and_chain 'Publish the cert this ELK node to s3.' do
  cert mycacrt
  cert_and_chain_path "/etc/logstash/elk.login.gov.pem"
  suffix "legacy-elk"
end

# NOTE: redo using service discovery cookbook helpers
# Download root CA cert for elasticsearch node certs
aws_account_id = AwsMetadata.get_aws_account_id
s3_root_cert_url = "s3://login-gov.internal-certs.#{aws_account_id}-us-west-2/#{node.chef_environment}/elasticsearch/root-ca.pem"

execute 'download root CA cert' do
  command "aws s3 cp #{s3_root_cert_url} /etc/elasticsearch/"
  not_if { ::File.exist?('/etc/elasticsearch/root-ca.pem') }
end

# install logstash
remote_file '/usr/share/logstash.deb' do
  source node['elk']['logstashdeb']
end
dpkg_package 'logstash' do
  source '/usr/share/logstash.deb'
end

execute 'update-ca-certificates -f'

# install cloudwatch plugin
git '/usr/share/logstash-codec-cloudtrail' do
  repository 'https://github.com/timothy-spencer/logstash-codec-cloudtrail.git'
  revision "v#{node['elk']['logstash-codec-cloudtrail-version']}"
end

execute "rbenv exec gem build logstash-codec-cloudtrail.gemspec" do
  cwd '/usr/share/logstash-codec-cloudtrail'
end

execute "bin/logstash-plugin install /usr/share/logstash-codec-cloudtrail/logstash-codec-cloudtrail-#{node['elk']['logstash-codec-cloudtrail-version']}.gem" do
  cwd '/usr/share/logstash'
  notifies :run, 'execute[restart_cloudtraillogstash]', :delayed
  creates "/usr/share/logstash/vendor/cache/logstash-codec-cloudtrail-#{node['elk']['logstash-codec-cloudtrail-version']}.gem"
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
  notifies :run, 'execute[restart_logstash]', :delayed
end

file mycert do
  owner 'logstash'
end

# turn off the non-sv service
execute 'service logstash stop || true'
execute 'update-rc.d -f logstash remove'

# create the common outputs and services for all logstash instances
include_recipe 'runit'
%w{ logstash cloudtraillogstash cloudwatchlogstash }.each do |lsname|
  # set up sincedb entries so we don't rescan everything from the beginning of time
  template "/usr/share/logstash/.sincedb_#{lsname}" do
    source 'sincedb.erb'
    owner 'logstash'
    group 'logstash'
    not_if { File.exists?("/usr/share/logstash/.sincedb_#{lsname}") }
  end

  # set up data dirs for the other logstash instances
  directory "/usr/share/logstash/data_#{lsname}" do
    owner 'logstash'
    group 'logstash'
  end

  directory "/etc/logstash/#{lsname}conf.d"

  # We use /srv/tmp because we need a scratch directory that won't disappear on
  # reboot.
  directory "/srv/tmp for #{lsname}" do
    path '/srv/tmp'
    mode '0755'
  end
  directory "/srv/tmp/#{lsname}" do
    owner 'logstash'
    group 'logstash'
    mode '0700'
  end

  template "/etc/logstash/#{lsname}conf.d/30-s3output.conf" do
    source '30-s3output.conf.erb'
    variables ({
      :aws_region => node['ec2']['placement_availability_zone'][0..-2],
      :aws_logging_bucket => node['elk']['aws_logging_bucket'],
      :tags => [lsname]
    })
    notifies :run, "execute[restart_#{lsname}]", :delayed
  end

  template "/etc/logstash/#{lsname}conf.d/30-ESoutput.conf" do
    source '30-ESoutput.conf.erb'
    variables ({
      :hostips => "\"#{elasticsearch_domain}\""
    })
    notifies :run, "execute[restart_#{lsname}]", :delayed
  end

  runit_service lsname do
    default_logger true
    sv_timeout 20
    options ({
      :home => '/usr/share/logstash',
      :max_heap => "#{(node['memory']['total'].to_i * 0.5).floor / 1024}M",
      :min_heap => "#{(node['memory']['total'].to_i * 0.2).floor / 1024}M",
      :gc_opts => '-XX:+UseParallelOldGC',
      :java_opts => '-Dio.netty.native.workdir=/etc/logstash/tmp -XX:HeapDumpPath=/dev/null',
      :tmpdir => "/srv/tmp/#{lsname}",
      :ipv4_only => false,
      :workers => 2,
      :debug => false,
      :user => 'logstash',
      :group => 'logstash',
      :start_down => true
    }.merge(params))
  end

  execute "restart_#{lsname}" do
    command "sv force-restart #{lsname} || true"
    action :nothing
  end
end

# clean up old logstash config that might be confusing
execute 'rm -rf /etc/logstash/conf.d'

# set up cloudtrail logstash config
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id

template "/etc/logstash/cloudtraillogstashconf.d/30-cloudtrailin.conf" do
  source '30-cloudtrailin.conf.erb'
  variables ({
    :aws_region => node['ec2']['placement_availability_zone'][0..-2],
    :cloudtrail_logging_bucket => "login-gov-cloudtrail-#{aws_account_id}"
  })
  notifies :run, 'execute[restart_cloudtraillogstash]', :delayed
end

template "/etc/logstash/cloudtraillogstashconf.d/70-elblogsin.conf" do
  source '70-elblogsin.conf.erb'
  variables ({
    :aws_region => node['ec2']['placement_availability_zone'][0..-2],
    :proxy_logging_bucket => node['elk']['proxy_logging_bucket'],
    :elb_prefix => node.chef_environment,
    :elb_logging_bucket => node['elk']['elb_logging_bucket']
  })
  notifies :run, 'execute[restart_cloudtraillogstash]', :delayed
end

template '/usr/share/logstash/.sincedb_proxyelb' do
  source 'sincedb.erb'
  owner 'logstash'
  group 'logstash'
  not_if { File.exists?("/usr/share/logstash/.sincedb_proxyelb") }
end
template "/usr/share/logstash/.sincedb_elb" do
  source 'sincedb.erb'
  owner 'logstash'
  group 'logstash'
  not_if { File.exists?("/usr/share/logstash/.sincedb_elb") }
end

template "/etc/logstash/cloudtraillogstashconf.d/60-analyticsin.conf" do
  source '60-analyticsin.conf.erb'
  variables ({
    :env => node.chef_environment,
    :aws_region => node['ec2']['placement_availability_zone'][0..-2],
    :analytics_logging_bucket => node['elk']['analytics_logging_bucket']
  })
  notifies :run, 'execute[restart_cloudtraillogstash]', :delayed
  only_if { node['elk']['analytics_logs'] }
end

(1..3).each do |i|
  template "/usr/share/logstash/.sincedb_analyticslogstash#{i}" do
    source 'sincedb.erb'
    owner 'logstash'
    group 'logstash'
    not_if { File.exists?("/usr/share/logstash/.sincedb_analyticslogstash#{i}") }
  end
end

template '/etc/logstash/logstash-template.json' do
  source 'logstash-template.json.erb'
  notifies :run, 'execute[restart_logstash]', :delayed
end

# set up filebeat (default) logstash config
template '/etc/logstash/logstashconf.d/40-beats.conf' do
  source '40-beats.conf.erb'
  variables ({
    :mycrt => "#{mycacrt}",
    :mykey => "#{mypkcs8}"
  })
  notifies :run, 'execute[restart_logstash]', :delayed
end

directory '/etc/logstash/tmp' do
  owner 'logstash'
  mode '0700'
end

# install kibana (grr, package doesn't work right now)
user 'kibana' do
  system true
end
group 'kibana' do
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
  variables ({
    :elasticsearch_domain => elasticsearch_domain
  })
  notifies :restart, 'runit_service[kibana]'
end

execute "wget #{node['elk']['kibanalogtrailplugin']}" do
  cwd '/tmp'
  creates "/tmp/#{node['elk']['kibanalogtrailplugin']}"
end

execute "bin/kibana-plugin install file:///tmp/#{node['elk']['kibanalogtrailplugin'].split('/').last}" do
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
directory "#{elastalertdir}/rules.d" do
  recursive true
end

execute 'pip install setuptools --upgrade'
execute "pip install elastalert==#{node.fetch('elk').fetch('elastalert').fetch('version')}" do
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
  variables ({
    :elasticsearch_domain => elasticsearch_domain
  })
  notifies :restart, 'runit_service[elastalert]'
end

%w{alb429.yaml alb5xx.yaml failedlogins.yaml invaliduser.yaml nologs.yaml proxyblock.yaml unknownip.yaml}.each do |t|
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
  home "#{elastalertdir}/home"
end
group 'elastalert' do
  system true
end
directory "#{elastalertdir}/home" do
  owner 'elastalert'
  group 'elastalert'
end

runit_service 'elastalert' do
  default_logger true
end

# set up the stuff that slurps in the vpc flow logs via cloudwatch
git '/usr/share/logstash-input-cloudwatch_logs' do
  repository 'https://github.com/lukewaite/logstash-input-cloudwatch-logs.git'
  revision "v#{node['elk']['logstash-input-cloudwatch-logs-version']}"
end

execute "rbenv exec gem build logstash-input-cloudwatch_logs.gemspec" do
  cwd '/usr/share/logstash-input-cloudwatch_logs'
end

execute "bin/logstash-plugin install /usr/share/logstash-input-cloudwatch_logs/logstash-input-cloudwatch_logs-#{node['elk']['logstash-input-cloudwatch-logs-version']}.gem" do
  cwd '/usr/share/logstash'
  notifies :run, 'execute[restart_cloudwatchlogstash]', :delayed
  creates "/usr/share/logstash/vendor/cache/logstash-input-cloudwatch_logs-#{node['elk']['logstash-input-cloudwatch-logs-version']}.gem"
end

template "/etc/logstash/cloudwatchlogstashconf.d/50-cloudwatchin.conf" do
  source '50-cloudwatchin.conf.erb'
  variables ({
    :aws_region => node['ec2']['placement_availability_zone'][0..-2],
    :env => node.chef_environment
  })
  notifies :run, 'execute[restart_cloudwatchlogstash]', :delayed
end

cron 'rerun elk discovery every 15 minutes' do
  action :create
  minute '0,15,30,45'
  command "cat #{node.fetch('elk').fetch('chef_zero_client_configuration')} >/dev/null && chef-client --local-mode -c #{node.fetch('elk').fetch('chef_zero_client_configuration')} -o 'role[elk_discovery]' 2>&1 >> /var/log/elk-discovery.log"
end
