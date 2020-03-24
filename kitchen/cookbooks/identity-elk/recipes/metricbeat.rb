version = node.fetch('metricbeat').fetch('version')

remote_file "/tmp/metricbeat-#{version}-amd64.deb" do
  source "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-#{version}-amd64.deb"
  action :create
end

dpkg_package "metricbeat-#{version}-amd64.deb" do
  source "/tmp/metricbeat-#{version}-amd64.deb"
end

template "/etc/metricbeat/metricbeat.yml" do
  source 'metricbeat.yml.erb'
  variables ({
    logstash_hosts: node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('hosts'),
    logstash_ssl_certificate_authorities: node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('tls').fetch('certificate_authorities')
  })
  notifies :restart, 'service[metricbeat]'
end

service 'metricbeat' do
  action :enable
end
