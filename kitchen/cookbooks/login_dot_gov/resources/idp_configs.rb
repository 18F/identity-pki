property :name, String

property :symlink_from, String

ConfigLoader = Chef::Recipe::ConfigLoader

action :create do
  %w{certs keys config}.each do |dir|
    directory "#{name}/#{dir}" do
      owner node.fetch('login_dot_gov').fetch('system_user')
      group node.fetch('login_dot_gov').fetch('web_system_user')
    end
  end

  # TODO: don't generate YAML with erb, that's an antipattern
  template "#{name}/config/experiments.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  # TODO remove saml.crt without suffix
  %w{saml.crt saml2018.crt saml2019.crt}.each do |certfile|
    file "#{name}/certs/#{certfile}" do
      action :create
      content ConfigLoader.load_config(node, certfile)
      manage_symlink_source true
      subscribes :create, 'resource[git]', :immediately
      user node['login_dot_gov']['system_user']
    end
  end

  # TODO remove saml.key.enc without suffix
  %w{oidc.key saml.key.enc saml2018.key.enc saml2019.key.enc}.each do |keyfile|
    file "#{name}/keys/#{keyfile}" do
      action :create
      content ConfigLoader.load_config(node, keyfile)
      manage_symlink_source true
      subscribes :create, 'resource[git]', :immediately
      owner node.fetch('login_dot_gov').fetch('system_user')
      group node.fetch('login_dot_gov').fetch('web_system_user')
      mode '0640'
      sensitive true
    end
  end

  file "#{name}/keys/oidc.pub" do
    action :create
    content ConfigLoader.load_config(node, 'oidc.pub')
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  file "#{name}/keys/equifax_rsa" do
    action :create
    content ConfigLoader.load_config(node, "equifax_ssh_privkey")
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    owner node.fetch('login_dot_gov').fetch('system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    mode '0640'
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

  # create symlinks if requested
  if new_resource.symlink_from
    [
      'config/experiments.yml',
      'certs/saml.crt',
      'certs/saml2018.crt',
      'certs/saml2019.crt',
      'keys/oidc.key',
      'keys/oidc.pub',
      'keys/saml.key.enc',
      'keys/saml2018.key.enc',
      'keys/saml2019.key.enc',
      'keys/equifax_rsa',
      'keys/equifax_gpg.pub',
    ].each do |filename|
      link "#{new_resource.symlink_from}/#{filename}" do
        to "#{new_resource.name}/#{filename}"
        owner node.fetch('login_dot_gov').fetch('system_user')
        group node.fetch('login_dot_gov').fetch('system_user')
      end
    end
  end
end
