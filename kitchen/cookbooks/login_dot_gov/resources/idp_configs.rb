property :name, String, default: '/srv/idp/shared'

action :create do
  encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

  %w{certs keys config}.each do |dir|
    directory "/srv/idp/shared/#{dir}" do
      group node['login_dot_gov']['system_user']
      owner node['login_dot_gov']['system_user']
      recursive true
    end
  end

  template "#{name}/config/application.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    variables({
      allow_third_party_auth: node['login_dot_gov']['allow_third_party_auth'],
      domain_name: "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
      google_analytics_key: encrypted_config['google_analytics_key'],
      idp_sso_target_url: "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
      logins_per_ip_limit: node['login_dot_gov']['logins_per_ip_limit'],
      logins_per_ip_period: node['login_dot_gov']['logins_per_ip_period'],
      mailer_domain_name: "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
      newrelic_license_key: encrypted_config['newrelic_license_key'],
      otp_delivery_blocklist_bantime: node['login_dot_gov']['otp_delivery_blocklist_bantime'],
      otp_delivery_blocklist_findtime: node['login_dot_gov']['otp_delivery_blocklist_findtime'],
      otp_delivery_blocklist_maxretry: node['login_dot_gov']['otp_delivery_blocklist_maxretry'],
      proofing_vendors: node['login_dot_gov']['proofing_vendors'],
      pt_mode: node['login_dot_gov']['pt_mode'],
      redis_url: encrypted_config['redis_url'],
      requests_per_ip_limit: node['login_dot_gov']['requests_per_ip_limit'],
      requests_per_ip_period: node['login_dot_gov']['requests_per_ip_period'],
      saml_passphrase: encrypted_config['saml_passphrase'],
      secret_key_base: encrypted_config['secret_key_base'],
      smtp_settings: encrypted_config['smtp_settings'],
      support_url: "#{node['login_dot_gov']['domain_name']}/support",
      twilio_accounts: encrypted_config['twilio_accounts']
    })
  end

  cookbook_file "#{name}/certs/saml.crt" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  file "#{name}/keys/saml.key.enc" do
    action :create
    content encrypted_config['saml.key.enc']
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end
end
