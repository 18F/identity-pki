# This cookbook installs filebeat to send stuff to logstash

# finds and sets active logstash endpoint for the environment
# TODO remove this code and statically set logstash host to logstash.login.gov.inernal:5044 once the
# production upgrade is complete.
node.default['filebeat']['config']['output']['logstash']['hosts'] = find_active_logstash
node.default['filebeat']['config']['output']['logstash']['ssl']['certificate_authorities'] = ["/etc/ssl/certs/ca-certificates.crt"]

#############################
# Chef Server Compatibility #
#############################
#
# If we are running with a chef server, we can use the chef server's node search
# functionality to find other services.
#
# However, if we are running chef-zero locally as we do in test kitchen unit
# tests and bootstrapping ASGs, we need to rely on some other mechanism.  Our
# service_discovery cookbook abstracts out this service discovery and has a
# helper resource to install the certificates of the discovered nodes locally,
# so we can call that.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  # TODO: Don't use this suffix, just use the base host certificate
  install_certificates 'Installing ELK certificates to ca-certificates' do
    service_tag_key node['elk']['elk_tag_key']
    service_tag_value node['elk']['elk_tag_value']
    install_directory '/usr/local/share/ca-certificates'
    suffix 'legacy-elk'
    notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
    notifies :restart, 'service[filebeat]'
  end
else
  elk_nodes = search(:node, "elk_pubkey:* AND chef_environment:#{node.chef_environment}",
                     :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'pubkey' => ['elk','pubkey'], 'name' => ['name']})
  elk_nodes.each do |n|
    file "/usr/local/share/ca-certificates/#{n['name']}.crt" do
      content n['pubkey']
      mode '0644'
      notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
      notifies :restart, 'service[filebeat]'
    end
  end
end

execute '/usr/sbin/update-ca-certificates' do
  action :nothing
end

include_recipe 'filebeat'

node['elk']['filebeat']['logfiles'].each do |logitem|
  logfile = logitem.fetch('log')
  filebeat_prospector logfile.gsub(/[\/\*]/,'_') do
    paths [logfile]
    document_type "#{logitem.fetch('type')}"
    ignore_older '24h'
    scan_frequency '15s'
    harvester_buffer_size 16384
    fields 'type' => logfile
    if logitem['format'] == 'json'
      json_keys_under_root true
      json_add_error_key true
      json_message_key 'id'
    end
    # XXX make sure to nuke this once the auditctl stuff is in the base image
    exclude_lines [ 'name=./var/lib/filebeat', 'exe=./usr/share/filebeat/bin/filebeat' ]
  end
end

# This will be true if the instance is auto scaled.
if node.fetch("provisioner", {"auto-scaled" => false}).fetch("auto-scaled")
  cron 'rerun elk filebeat discovery every 15 minutes' do
    action :create
    minute '0,15,30,45'
    command "cat #{node['elk']['chef_zero_client_configuration']} && chef-client --local-mode -c #{node['elk']['chef_zero_client_configuration']} -o 'role[filebeat_discovery]' 2>&1 >> /var/log/filebeat-discovery.log"
  end
end

