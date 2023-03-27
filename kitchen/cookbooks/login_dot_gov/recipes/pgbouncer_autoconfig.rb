# Automatically configure PGBouncer users and databases based on application.yml
app_name = 'idp'

# This seems to get killed when baked in, so recreating
directory '/var/run/postgresql' do
  owner 'postgres'
  group 'postgres'
  mode '0755'
end

# Override default pgbouncer.ini with any tuning adjustments
template '/etc/pgbouncer/pgbouncer.ini' do
  source 'pgbouncer.ini.erb'
  variables({
    auth_type:            node['login_dot_gov']['pgbouncer']['auth_type'],
    default_pool_size:    node['login_dot_gov']['pgbouncer']['default_pool_size'],
    max_client_conn:      node['login_dot_gov']['pgbouncer']['max_client_conn'],
    max_db_connections:   node['login_dot_gov']['pgbouncer']['max_db_connections'],
    max_user_connections: node['login_dot_gov']['pgbouncer']['max_user_connections'],
    min_pool_size:        node['login_dot_gov']['pgbouncer']['min_pool_size'],
    pool_mode:            node['login_dot_gov']['pgbouncer']['pool_mode'],
    reserve_pool_size:    node['login_dot_gov']['pgbouncer']['reserve_pool_size'],
    reserve_pool_timeout: node['login_dot_gov']['pgbouncer']['reserve_pool_timeout'],
    server_check_delay:   node['login_dot_gov']['pgbouncer']['server_check_delay'],
    server_reset_query:   node['login_dot_gov']['pgbouncer']['server_reset_query'],
  })
  owner 'postgres'
  group 'postgres'
  mode '0640'
end

ruby_block 'Build pgbouncer configuration from application.yml' do
  block do
    require 'digest'

    config = {}

    config_raw = ConfigLoader.load_config(node, "#{app_name}/v1/application.yml", app: true)
    config_yaml = YAML.safe_load(config_raw)

    ['host', 'name', 'username', 'password'].each do |k|
      config[k] = config_yaml['production']["#{node['login_dot_gov']['pgbouncer']['config_prefix']}#{k}"]
    end

    # Automatically MD5 if using MD5 mode auth and provided secret is not already
    # MD5 format.  Note that better options like SCRAM have limitations
    # requiring more engineering to support well here.
    if (config['password'] !~ /^md5[a-f0-9]{32}$/) && (node['login_dot_gov']['pgbouncer']['auth_type'] == 'md5')
      config['password'] = 'md5' + Digest::MD5.hexdigest("#{config['password']}#{config['username']}")
    end

    # Create database defitions for the app database and system postgres database
    # This needs modification to support multiple backends in PGBouncer
    node.default['databases'] = [
      {
        name:     config['name'],
        host:     config['host'],
        username: config['username'],
      },
      {
        name:     'postgres',
        host:     config['host'],
        username: config['username'],
      },
    ]

    node.default['userlist'] = [
      {
        username: config['username'],
        password: config['password'],
      },
    ]
  end
end

template '/etc/pgbouncer/pgbouncer-dbs.ini' do
  source 'pgbouncer-dbs.ini.erb'
  variables(
    lazy do
      {
        databases: node['databases'],
      }
    end
  )
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/pgbouncer/userlist.txt' do
  source 'pgbouncer-userlist.txt.erb'
  variables(
    lazy do
      {
        userlist: node['userlist'],
      }
    end
  )
  owner 'postgres'
  group 'root'
  mode '0400'
end

service 'pgbouncer' do
  action :start

  supports({
    restart: true,
    status:  true,
    start:   true,
    stop:    true,
  })
end
