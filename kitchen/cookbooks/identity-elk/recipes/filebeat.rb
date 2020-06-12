# This cookbook installs filebeat to send stuff to logstash

# TODO: Don't use this suffix, just use the base host certificate
install_certificates 'Installing ELK certificates to ca-certificates' do
  service_tag_key node.fetch('elk').fetch('elk_tag_key')
  service_tag_value node.fetch('elk').fetch('elk_tag_value')
  install_directory '/usr/local/share/ca-certificates'
  suffix 'legacy-elk'
  notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
end

execute '/usr/sbin/update-ca-certificates' do
  action :nothing
  notifies :restart, 'service[filebeat]'
end

filebeat_install 'default' do
  version node.fetch('filebeat').fetch('version')
  notifies :enable, 'service[filebeat]'
end

directory '/etc/systemd/system/filebeat.service.d'

# override default systemd config to log to file (removes -e when loading)
cookbook_file '/etc/systemd/system/filebeat.service.d/enable_logging.conf' do
  mode '0755'
  notifies :restart, 'service[filebeat]'
end

template "/etc/filebeat/filebeat.yml" do
  source 'filebeat.yml.erb'
  variables ({
    :logstash_hosts => node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('hosts'),
    :logstash_ssl_certificate_authorities => node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('tls').fetch('certificate_authorities')
  })
  notifies :restart, 'service[filebeat]'
end

directory '/etc/filebeat/inputs.d'

template "/etc/filebeat/inputs.d/default.yml" do
  source 'filebeat_inputs_default.yml.erb'
  variables ({
    :logfiles => node.fetch('filebeat').fetch('logfiles'),
  })
  notifies :restart, 'service[filebeat]'
end

service 'filebeat' do
  action :enable
end

cron 'rerun elk filebeat discovery every 5 minutes' do
  action :create
  minute '*/5'
  command "flock -n /tmp/filebeat_discovery.lock -c \"cat #{node['elk']['chef_zero_client_configuration']} >/dev/null && chef-client --local-mode -c #{node['elk']['chef_zero_client_configuration']} -o 'role[filebeat_discovery]' 2>&1 >> /var/log/filebeat-discovery.log\""
end
