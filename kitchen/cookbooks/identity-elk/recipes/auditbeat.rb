version = node.fetch('auditbeat').fetch('version')

remote_file "/tmp/auditbeat-#{version}-amd64.deb" do
  source "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-#{version}-amd64.deb"
  action :create
end

directory '/etc/systemd/system/auditbeat.service.d'

# override default systemd config to log to file (removes -e when loading)
cookbook_file '/etc/systemd/system/auditbeat.service.d/enable_logging.conf' do
  mode '0755'
  notifies :restart, 'service[auditbeat]'
end

dpkg_package "auditbeat-#{version}-amd64.deb" do
  source "/tmp/auditbeat-#{version}-amd64.deb"
end

template "/etc/auditbeat/auditbeat.yml" do
  source 'auditbeat.yml.erb'
  variables ({
    logstash_hosts: node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('hosts'),
    logstash_ssl_certificate_authorities: node.fetch('filebeat').fetch('config').fetch('output').fetch('logstash').fetch('tls').fetch('certificate_authorities')
  })
  notifies :restart, 'service[auditbeat]'
end

service 'auditbeat' do
  action :enable
end
