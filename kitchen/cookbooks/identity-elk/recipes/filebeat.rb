# This cookbook installs filebeat to send stuff to logstash

node.default['filebeat']['config']['output']['logstash']['hosts'] = ["elk.login.gov.internal:5044"]

# set up trusted cert from elk node(s)
elk_nodes = search(:node, "elk_pubkey:* AND chef_environment:#{node.chef_environment}", 'elk_pubkey')
elk_nodes.each do |n|
  file "/usr/local/share/ca-certificates/#{n.name}.crt" do
    content n['elk']['pubkey']
    mode '0644'
    notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
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
  end
end

