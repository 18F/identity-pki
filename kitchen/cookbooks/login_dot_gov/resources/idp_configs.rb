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

  # Set app's domain name: (secure.login.gov in prod, otherwise idp.<env>.login.gov)
  domain_name = node.chef_environment == 'prod' ? 'secure.login.gov' : "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  participate_in_dap = encrypted_config['google_analytics_key'].nil? ? 'false' : 'true'

  template "#{name}/config/application.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    sensitive true
    variables({
      allow_third_party_auth: node['login_dot_gov']['allow_third_party_auth'],
      attribute_cost: node['login_dot_gov']['attribute_cost'],
      attribute_encryption_key: (encrypted_config['attribute_encryption_key'] || node['login_dot_gov']['attribute_encryption_key']),
      attribute_encryption_key_queue: node['login_dot_gov']['attribute_encryption_key_queue'],
      aws_kms_key_id: node['login_dot_gov']['aws_kms_key_id'],
      aws_region: node['login_dot_gov']['aws_region'],
      dashboard_api_token: encrypted_config['dashboard_api_token'],
      dashboard_url: encrypted_config['dashboard_url'],
      domain_name: domain_name,
      enable_test_routes: node['login_dot_gov']['enable_test_routes'],
      email_encryption_key: (encrypted_config['email_encryption_key'] || node['login_dot_gov']['email_encryption_key']),
      email_from: node['login_dot_gov']['email_from'],
      enable_i18n_mode: node['login_dot_gov']['enable_i18n_mode'],
      enable_identity_verification: node['login_dot_gov']['enable_identity_verification'],
      equifax_avs_username: encrypted_config['equifax_avs_username'],
      equifax_eid_username: encrypted_config['equifax_eid_username'],
      equifax_endpoint: encrypted_config['equifax_endpoint'],
      equifax_gpg_email: node['login_dot_gov']['equifax_gpg_email'],
      equifax_password: encrypted_config['equifax_password'],
      equifax_phone_username: encrypted_config['equifax_phone_username'],
      equifax_sftp_directory: node['login_dot_gov']['equifax_sftp_directory'],
      equifax_sftp_host: node['login_dot_gov']['equifax_sftp_host'],
      equifax_sftp_username: node['login_dot_gov']['equifax_sftp_username'],
      equifax_ssh_passphrase: encrypted_config['equifax_ssh_passphrase'],
      google_analytics_key: encrypted_config['google_analytics_key'],
      hmac_fingerprinter_key: encrypted_config['hmac_fingerprinter_key'],
      hmac_fingerprinter_key_queue: node['login_dot_gov']['hmac_fingerprinter_key_queue'],
      idp_sso_target_url: node['login_dot_gov']['idp_sso_target_url'],
      idv_attempt_window_in_hours: node['login_dot_gov']['idv_attempt_window_in_hours'],
      idv_max_attempts: node['login_dot_gov']['idv_max_attempts'],
      logins_per_ip_limit: node['login_dot_gov']['logins_per_ip_limit'],
      logins_per_ip_period: node['login_dot_gov']['logins_per_ip_period'],
      mailer_domain_name: "https://#{domain_name}",
      min_password_score: node['login_dot_gov']['min_password_score'],
      password_max_attempts: node['login_dot_gov']['password_max_attempts'],
      newrelic_browser_app_id: encrypted_config['newrelic_browser_app_id'],
      newrelic_browser_key: encrypted_config['newrelic_browser_key'],
      newrelic_license_key: encrypted_config['newrelic_license_key'],
      otp_delivery_blocklist_bantime: node['login_dot_gov']['otp_delivery_blocklist_bantime'],
      otp_delivery_blocklist_findtime: node['login_dot_gov']['otp_delivery_blocklist_findtime'],
      otp_delivery_blocklist_maxretry: node['login_dot_gov']['otp_delivery_blocklist_maxretry'],
      otp_valid_for: node['login_dot_gov']['otp_valid_for'],
      participate_in_dap: participate_in_dap,
      password_pepper: encrypted_config['password_pepper'],
      password_strength_enabled: node['login_dot_gov']['password_strength_enabled'],
      proofing_vendors: node['login_dot_gov']['proofing_vendors'],
      proxy_addr: node['login_dot_gov']['proxy_addr'],
      proxy_port: node['login_dot_gov']['proxy_port'],
      queue_health_check_dead_interval_seconds: node['login_dot_gov']['queue_health_check_dead_interval_seconds'],
      queue_health_check_frequency_seconds: node['login_dot_gov']['queue_health_check_frequency_seconds'],
      reauthn_window: node['login_dot_gov']['reauthn_window'],
      recovery_code_length: node['login_dot_gov']['recovery_code_length'],
      redis_url: encrypted_config['redis_url'],
      requests_per_ip_limit: node['login_dot_gov']['requests_per_ip_limit'],
      requests_per_ip_period: node['login_dot_gov']['requests_per_ip_period'],
      saml_passphrase: encrypted_config['saml_passphrase'],
      scrypt_cost: node['login_dot_gov']['scrypt_cost'],
      secret_key_base_idp: encrypted_config['secret_key_base_idp'],
      session_check_delay: node['login_dot_gov']['session_check_delay'],
      session_check_frequency: node['login_dot_gov']['session_check_frequency'],
      session_encryption_key: encrypted_config['session_encryption_key'],
      session_timeout_in_minutes: node['login_dot_gov']['session_timeout_in_minutes'],
      session_timeout_warning_seconds: node['login_dot_gov']['session_timeout_warning_seconds'],
      smtp_settings: encrypted_config['smtp_settings'],
      stale_session_window: node['login_dot_gov']['stale_session_window'],
      support_email: node['login_dot_gov']['support_email'],
      support_url: node['login_dot_gov']['support_url'],
      twilio_accounts: encrypted_config['twilio_accounts'],
      twilio_record_voice: node['login_dot_gov']['twilio_record_voice'],
      use_dashboard_service_providers: encrypted_config['use_dashboard_service_providers'],
      use_kms: node['login_dot_gov']['use_kms'],
      valid_authn_contexts: node['login_dot_gov']['valid_authn_contexts'],
    })
  end

  template "#{name}/config/experiments.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  if encrypted_config['saml.crt']
    file "#{name}/certs/saml.crt" do
      action :create
      content encrypted_config['saml.crt']
      manage_symlink_source true
      subscribes :create, 'resource[git]', :immediately
      user node['login_dot_gov']['system_user']
    end
  else
    # Do not allow the hardcoded certificate when in prod
    if node.chef_environment == 'prod'
      Chef::Log.fatal 'ERROR: Must specify SAML/OIDC public certificate in data bag (saml.crt)'
      raise
    end

    # Help push developers to use the data bag for this configuration since the private
    # key is already configured using the databag. (see saml.key.enc)
    log 'idp_configs' do
      message 'No SAML/OIDC public certificate found in data bag, using default'
      level :warn
    end

    cookbook_file "#{name}/certs/saml.crt" do
      action :create
      manage_symlink_source true
      subscribes :create, 'resource[git]', :immediately
      user node['login_dot_gov']['system_user']
    end
  end

  file "#{name}/keys/saml.key.enc" do
    action :create
    content encrypted_config['saml.key.enc']
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    sensitive true
  end

  file "#{name}/keys/equifax_rsa" do
    action :create
    content encrypted_config['equifax_ssh_privkey']
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    sensitive true
  end
end
