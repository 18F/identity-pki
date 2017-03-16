# This cookbook installs filebeat to send stuff to logstash

node.default['filebeat']['config']['output']['logstash']['hosts'] = ["elk.login.gov.internal:5044"]
node.default['filebeat']['config']['output']['logstash']['ssl']['certificate_authorities'] = ["/etc/ssl/certs/ca-certificates.crt"]


# set up trusted cert from elk node(s)
elk_nodes = search(:node, "elk_pubkey:* AND chef_environment:#{node.chef_environment}", :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'pubkey' => ['elk','pubkey'], 'name' => ['name']})
elk_nodes.each do |n|
  file "/usr/local/share/ca-certificates/#{n['name']}.crt" do
    content n['pubkey']
    mode '0644'
    notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
    notifies :restart, 'service[filebeat]'
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

