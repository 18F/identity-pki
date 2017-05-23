resource_name :psql_config

property :name, String, default: '/usr/local/share/aws'

action :create do
  directory '/usr/local/share/aws' do
    owner 'root'
    group 'root'
    mode 0755
    recursive true
  end

  remote_file "#{node['login_dot_gov']['sslrootcert']}" do
    owner 'root'
    group 'root'
    mode 0755
    sensitive true # nothing sensitive but using to remove unnecessary output
    source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
    action :create
  end
end
