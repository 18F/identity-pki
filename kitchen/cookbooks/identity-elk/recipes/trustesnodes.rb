
# dynamically slurp in all the ES nodes and their certs
esnodes = search(:node, "elk_espubkey:* AND chef_environment:#{node.chef_environment}", :filter_result => { 'ipaddress' => [ 'ipaddress' ], 'escert' => ['elk','espubkey'], 'name' => ['name']})

directory '/etc/elasticsearch'

# trust ES certs so that kibana/logstash will connect
esnodes.each do |h|
  file "/usr/local/share/ca-certificates/es_#{h['name']}.crt" do
    content h['escert']
    mode '0644'
    notifies :run, 'execute[/usr/sbin/update-ca-certificates]', :immediately
  end

  if File.exists?('/etc/elasticsearch/elasticsearch.yml')
    crtowner = 'elasticsearch'
  else
    crtowner = 'root'
  end

  file "/etc/elasticsearch/es_#{h['name']}.crt" do
    content h['escert']
    owner crtowner
    group crtowner
    mode '0644'
  end
end

execute '/usr/sbin/update-ca-certificates' do
  action :nothing
end

