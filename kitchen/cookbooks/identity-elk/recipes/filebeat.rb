# This cookbook installs filebeat to send stuff to logstash

# If we were running with a chef server, we could use the chef server's node
# search functionality to find other services.
#
# However, we are running chef-zero locally, so we need to rely on some other
# mechanism.  Our service_discovery cookbook abstracts out this service
# discovery and has a helper resource to install the certificates of the
# discovered nodes locally, so we can call that.
# TODO: Don't use this suffix, just use the base host certificate
install_certificates 'Installing ELK certificates to ca-certificates' do
  service_tag_key node['elk']['elk_tag_key']
  service_tag_value node['elk']['elk_tag_value']
  install_directory '/usr/local/share/ca-certificates'
  suffix 'legacy-elk'
  notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
end

execute '/usr/sbin/update-ca-certificates' do
  action :nothing
  notifies :reload, 'service[filebeat]'
end

service 'filebeat' do
  reload_command 'systemctl force-reload filebeat.service'
end

filebeat_install 'default' do
  version '6.4.2'
end

filebeat_conf = {
  'output.logstash.hosts' => ['logstash.login.gov.internal:5044'],
  'output.logstash.ssl.certificate_authorities' => ["/etc/ssl/certs/ca-certificates.crt"]
}

filebeat_config 'default' do
  config filebeat_conf
end

node['elk']['filebeat']['logfiles'].each do |logitem|
  logfile = logitem.fetch('log')

  conf = {
    'enabled' => true,
    'harvester_buffer_size' => 16384,
    'ignore_older' => '24h',
    'paths' => [logfile],
    'scan_frequency' => '15s',
    'type' => 'log'
  }

  filebeat_prospector logfile.gsub(/[\/\*]/,'_') do
    config conf
  end
end

filebeat_service 'default'

cron 'rerun elk filebeat discovery every 15 minutes' do
  action :create
  minute '0,15,30,45'
  command "cat #{node['elk']['chef_zero_client_configuration']} >/dev/null && chef-client --local-mode -c #{node['elk']['chef_zero_client_configuration']} -o 'role[filebeat_discovery]' 2>&1 >> /var/log/filebeat-discovery.log"
end
