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
    sensitive true
    variables({
      allow_third_party_auth: node['login_dot_gov']['allow_third_party_auth'],
      attribute_cost: node['login_dot_gov']['attribute_cost'],
      attribute_encryption_key: (encrypted_config['attribute_encryption_key'] || node['login_dot_gov']['attribute_encryption_key']),
      attribute_encryption_key_queue: node['login_dot_gov']['attribute_encryption_key_queue'],
      aws_kms_key_id: node['login_dot_gov']['aws_kms_key_id'],
      aws_region: node['login_dot_gov']['aws_region'],
      domain_name: "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
      enable_test_routes: node['login_dot_gov']['enable_test_routes'],
      email_encryption_cost: node['login_dot_gov']['email_encryption_cost'],
      email_encryption_key: (encrypted_config['email_encryption_key'] || node['login_dot_gov']['email_encryption_key']),
      email_from: node['login_dot_gov']['email_from'],
      enable_i18n_mode: node['login_dot_gov']['enable_i18n_mode'],
      google_analytics_key: encrypted_config['google_analytics_key'],
      hmac_fingerprinter_key: encrypted_config['hmac_fingerprinter_key'],
      hmac_fingerprinter_key_queue: node['login_dot_gov']['hmac_fingerprinter_key_queue'],
      idp_sso_target_url: node['login_dot_gov']['idp_sso_target_url'],
      idv_attempt_window_in_hours: node['login_dot_gov']['idv_attempt_window_in_hours'],
      idv_max_attempts: node['login_dot_gov']['idv_max_attempts'],
      logins_per_ip_limit: node['login_dot_gov']['logins_per_ip_limit'],
      logins_per_ip_period: node['login_dot_gov']['logins_per_ip_period'],
      mailer_domain_name: node['login_dot_gov']['mailer_domain_name'],
      min_password_score: node['login_dot_gov']['min_password_score'],
      password_max_attempts: node['login_dot_gov']['password_max_attempts'],
      newrelic_browser_app_id: encrypted_config['newrelic_browser_app_id'],
      newrelic_browser_key: encrypted_config['newrelic_browser_key'],
      newrelic_license_key: encrypted_config['newrelic_license_key'],
      otp_delivery_blocklist_bantime: node['login_dot_gov']['otp_delivery_blocklist_bantime'],
      otp_delivery_blocklist_findtime: node['login_dot_gov']['otp_delivery_blocklist_findtime'],
      otp_delivery_blocklist_maxretry: node['login_dot_gov']['otp_delivery_blocklist_maxretry'],
      otp_valid_for: node['login_dot_gov']['otp_valid_for'],
      participate_in_dap: node['login_dot_gov']['participate_in_dap'],
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
      secret_key_base: encrypted_config['secret_key_base'],
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
      use_kms: node['login_dot_gov']['use_kms'],
      valid_authn_contexts: node['login_dot_gov']['valid_authn_contexts'],
      valid_service_providers: encrypted_config['valid_service_providers']
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
