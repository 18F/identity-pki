# This cookbook installs filebeat to send stuff to logstash

node.default['filebeat']['config']['output']['logstash']['hosts'] = ["elk.login.gov.internal:5044"]
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
  logfile = logitem['log']
  filebeat_prospector logfile.gsub(/[\/\*]/,'_') do
    paths [logfile]
    document_type "#{logitem.type}"
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

