property :name, String, default: '/srv/idp/shared'

ConfigLoader = Chef::Recipe::ConfigLoader

action :create do
  %w{certs keys config}.each do |dir|
    directory "/srv/idp/shared/#{dir}" do
      owner node.fetch('login_dot_gov').fetch('system_user')
      group node.fetch('login_dot_gov').fetch('web_system_user')

      recursive false

      # set group sticky bit so configs are readable by web_system_user group
      mode '2755'
    end
  end

  # TODO: don't generate YAML with erb, that's an antipattern
  template "#{name}/config/experiments.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  %w{saml.crt saml2018.crt}.each do |certfile|
    if ConfigLoader.load_config_or_nil(node, certfile)
      file "#{name}/certs/#{certfile}" do
        action :create
        content ConfigLoader.load_config(node, certfile)
        manage_symlink_source true
        subscribes :create, 'resource[git]', :immediately
        user node['login_dot_gov']['system_user']
      end
    else
      # Do not allow the hardcoded certificate when in prod
      if node.chef_environment == 'prod'
        Chef::Log.fatal 'ERROR: Must specify SAML/OIDC public certificate in data bag (#{certfile})'
        raise
      end

      # Help push developers to use the data bag for this configuration since the private
      # key is already configured using the databag. (see saml.key.enc)
      log 'idp_configs' do
        message 'No SAML/OIDC public certificate found in data bag, using default'
        level :warn
      end

      cookbook_file "#{name}/certs/#{certfile}" do
        action :create
        manage_symlink_source true
        subscribes :create, 'resource[git]', :immediately
        user node['login_dot_gov']['system_user']
      end
    end
  end

  %w{saml.key.enc saml2018.key.enc}.each do |keyfile|
    file "#{name}/keys/#{keyfile}" do
      action :create
      content ConfigLoader.load_config(node, keyfile)
      manage_symlink_source true
      subscribes :create, 'resource[git]', :immediately
      owner node.fetch('login_dot_gov').fetch('system_user')
      group node.fetch('login_dot_gov').fetch('web_system_user')
      sensitive true
    end
  end

  file "#{name}/keys/equifax_rsa" do
    action :create
    content ConfigLoader.load_config(node, "equifax_ssh_privkey")
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    owner node.fetch('login_dot_gov').fetch('system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    sensitive true
  end

  file "#{name}/keys/equifax_gpg.pub" do
    action :create
    content ConfigLoader.load_config(node, "equifax_gpg_public_key")
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    owner node.fetch('login_dot_gov').fetch('system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    sensitive true
  end
end
