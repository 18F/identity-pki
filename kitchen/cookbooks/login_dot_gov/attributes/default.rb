#
# Cookbook Name:: login_dot_gov
# Attributes:: default
#
default['login_dot_gov']['admin_email']                               = 'justin.grevich@gsa.gov'
default['login_dot_gov']['app_names']                                 = []
default['login_dot_gov']['dev_users']                                 = []
default['login_dot_gov']['rails_env']                                 = 'production'
default['login_dot_gov']['ruby_version']                              = '2.3.1'
default['login_dot_gov']['system_user']                               = 'ubuntu'

# used to turn off app startup and migrations and other things so that we can
# run idp_base to generate a mostly-populated AMI with packer
default['login_dot_gov']['setup_only']                                = false

# idp config
default['login_dot_gov']['allow_third_party_auth']                    = 'false'
default['login_dot_gov']['aws_kms_key_id']                            = 'not-used-yet'
default['login_dot_gov']['aws_region']                                = 'not-used-yet'
default['login_dot_gov']['domain_name']                               = 'login.gov'
default['login_dot_gov']['email_encryption_cost']                     = '4000$8$4$' # SCrypt::Engine.calibrate(max_time: 0.5)
default['login_dot_gov']['email_encryption_key']                      = 'change-this-immediately-with-rake-secret-2086dfbd15f5b0c584f3664422a1d3409a0d2aa6084f65b6ba57d64d4257431c124158670c7655e45cabe64194f7f7b6c7970153c285bdb8287ec0c4f7553e25'
default['login_dot_gov']['email_from']                                = 'no-reply@login.gov'
default['login_dot_gov']['enable_i18n_mode']                          = 'false'
default['login_dot_gov']['enable_test_routes']                        = 'false'
default['login_dot_gov']['google_analytics_key']                      = 'UA-XXXXXX'
default['login_dot_gov']['hmac_fingerprinter_key']                    = 'change-this-immediately-with-rake-secret'
default['login_dot_gov']['idp_sso_target_url']                        = ''
default['login_dot_gov']['idv_attempt_window_in_hours']               = '24'
default['login_dot_gov']['idv_max_attempts']                          = '3'
default['login_dot_gov']['logins_per_ip_limit']                       = '20'
default['login_dot_gov']['logins_per_ip_period']                      = '8'
default['login_dot_gov']['mailer_domain_name']                        = 'https://login.gov'
default['login_dot_gov']['min_password_score']                        = '3'
default['login_dot_gov']['newrelic_browser_app_id']                   = ''
default['login_dot_gov']['newrelic_browser_key']                      = ''
default['login_dot_gov']['newrelic_license_key']                      = ''
default['login_dot_gov']['otp_delivery_blocklist_bantime']            = '10'
default['login_dot_gov']['otp_delivery_blocklist_findtime']           = '5'
default['login_dot_gov']['otp_delivery_blocklist_maxretry']           = '5'
default['login_dot_gov']['otp_valid_for']                             = '5'
default['login_dot_gov']['participate_in_dap']                        = 'false'
default['login_dot_gov']['password_pepper']                           = 'change-this-immediately-with-rake-secret'
default['login_dot_gov']['password_strength_enabled']                 = 'true'
default['login_dot_gov']['proofing_vendors']                          = 'mock'
default['login_dot_gov']['proxy_addr']                                = ''
default['login_dot_gov']['proxy_port']                                = ''
default['login_dot_gov']['queue_health_check_dead_interval_seconds']  = '240'
default['login_dot_gov']['queue_health_check_frequency_seconds']      = '120'
default['login_dot_gov']['reauthn_window']                            = '30'
default['login_dot_gov']['recovery_code_length']                      = '16'
default['login_dot_gov']['redis_url']                                 = 'redis://localhost:6379/0'
default['login_dot_gov']['requests_per_ip_limit']                     = '300'
default['login_dot_gov']['requests_per_ip_period']                    = '300'
default['login_dot_gov']['saml_passphrase']                           = ''
default['login_dot_gov']['scrypt_cost']                               = '4000$8$4$' # SCrypt::Engine.calibrate(max_time: 0.5)
default['login_dot_gov']['secret_key_base']                           = 'change-this-immediately-with-rake-secret-2086dfbd15f5b0c584f3664422a1d3409a0d2aa6084f65b6ba57d64d4257431c124158670c7655e45cabe64194f7f7b6c7970153c285bdb8287ec0c4f7553e25'
default['login_dot_gov']['session_check_delay']                       = '30'
default['login_dot_gov']['session_check_frequency']                   = '30'
default['login_dot_gov']['session_encryption_key']                    = 'change-this-immediately-with-rake-secret'
default['login_dot_gov']['session_timeout_in_minutes']                = '8'
default['login_dot_gov']['session_timeout_warning_seconds']           = '150'
default['login_dot_gov']['smtp_settings']                             = '{"address":"smtp.mandrillapp.com", "port":587, "authentication":"login", "enable_starttls_auto":true, "user_name":"user@gmail.com","password":"xxx"}'
default['login_dot_gov']['stale_session_window']                      = '180'
default['login_dot_gov']['support_email']                             = 'hello@login.gov'
default['login_dot_gov']['support_url']                               = '/contact'
default['login_dot_gov']['twilio_accounts']                           = '[{"sid":"sid", "auth_token":"token", "number":"9999999999"}]'
default['login_dot_gov']['use_kms']                                   = 'false'
default['login_dot_gov']['valid_authn_contexts']                      = '[]'
default['login_dot_gov']['valid_service_providers']                   = '[]'
