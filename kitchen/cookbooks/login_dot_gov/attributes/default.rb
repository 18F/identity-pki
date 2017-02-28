#
# Cookbook Name:: login_dot_gov
# Attributes:: default
#
default['login_dot_gov']['admin_email']                               = 'developer@login.gov'
default['login_dot_gov']['app_names']                                 = []
default['login_dot_gov']['dev_users']                                 = []
default['login_dot_gov']['rails_env']                                 = 'production'
default['login_dot_gov']['ruby_version']                              = '2.3.3'
default['login_dot_gov']['system_user']                               = 'ubuntu'
default['login_dot_gov']['fips']['version']                           = '2.0.13'
default['login_dot_gov']['fips']['url']                               = "https://www.openssl.org/source/openssl-fips-#{default['login_dot_gov']['fips']['version']}.tar.gz"
default['login_dot_gov']['fips']['checksum']                          = '3ff723f93901f750779a2e67ff15985c357f1a15c892c9504446fbc85c6f77da'
default['login_dot_gov']['openssl']['version']                        = '1.0.2f'
default['login_dot_gov']['openssl']['prefix']                         = "/opt/openssl-#{default['login_dot_gov']['openssl']['version']}"
default['login_dot_gov']['openssl']['url']                            = "https://www.openssl.org/source/openssl-#{default['login_dot_gov']['openssl']['version']}.tar.gz"
default['login_dot_gov']['openssl']['checksum']                       = '932b4ee4def2b434f85435d9e3e19ca8ba99ce9a065a61524b429a9d5e9b2e9c'
default['login_dot_gov']['openssl']['configure_flags']                = %W[ shared ]

# The gitref that we check out when deploying
default['login_dot_gov']['gitref']                          = 'master'

# used to turn off app startup and migrations and other things so that we can
# run idp_base to generate a mostly-populated AMI with packer
default['login_dot_gov']['setup_only']                                = false

# idp config
default['login_dot_gov']['allow_third_party_auth']                    = 'false'
default['login_dot_gov']['attribute_cost']                            = '4000$8$4$' # SCrypt::Engine.calibrate(max_time: 0.5)
default['login_dot_gov']['attribute_encryption_key']                  = 'change-this-immediately-with-rake-secret-2086dfbd15f5b0c584f3664422a1d3409a0d2aa6084f65b6ba57d64d4257431c124158670c7655e45cabe64194f7f7b6c7970153c285bdb8287ec0c4f7553e25'
default['login_dot_gov']['attribute_encryption_key_queue']            = '["old-key-one", "old-key-two"]'
default['login_dot_gov']['aws_kms_key_id']                            = 'not-used-yet'
default['login_dot_gov']['aws_region']                                = 'not-used-yet'
default['login_dot_gov']['domain_name']                               = 'login.gov'
default['login_dot_gov']['dashboard_api_key']                         = ''
default['login_dot_gov']['email_from']                                = 'no-reply@login.gov'
default['login_dot_gov']['enable_i18n_mode']                          = 'false'
default['login_dot_gov']['enable_test_routes']                        = 'false'
default['login_dot_gov']['google_analytics_key']                      = 'UA-XXXXXX'
default['login_dot_gov']['hmac_fingerprinter_key']                    = 'change-this-immediately-with-rake-secret'
default['login_dot_gov']['hmac_fingerprinter_key_queue']              = '["old-key-one", "old-key-two"]'
default['login_dot_gov']['idp_sso_target_url']                        = ''
default['login_dot_gov']['idv_attempt_window_in_hours']               = '24'
default['login_dot_gov']['idv_max_attempts']                          = '3'
default['login_dot_gov']['logins_per_ip_limit']                       = '20'
default['login_dot_gov']['logins_per_ip_period']                      = '8'
default['login_dot_gov']['mailer_domain_name']                        = 'https://login.gov'
default['login_dot_gov']['min_password_score']                        = '3'
default['login_dot_gov']['password_max_attempts']                     = '3'
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
default['login_dot_gov']['reauthn_window']                            = '120'
default['login_dot_gov']['recovery_code_length']                      = '5'
default['login_dot_gov']['redis_url']                                 = 'redis://localhost:6379/0'
default['login_dot_gov']['release_dir']                               = ''
default['login_dot_gov']['requests_per_ip_limit']                     = '300'
default['login_dot_gov']['requests_per_ip_period']                    = '300'
default['login_dot_gov']['saml_passphrase']                           = ''
default['login_dot_gov']['scrypt_cost']                               = '4000$8$4$' # SCrypt::Engine.calibrate(max_time: 0.5)
default['login_dot_gov']['secret_key_base_idp']                       = 'change-this-immediately-with-rake-secret-2086dfbd15f5b0c584f3664422a1d3409a0d2aa6084f65b6ba57d64d4257431c124158670c7655e45cabe64194f7f7b6c7970153c285bdb8287ec0c4f7553e25'
default['login_dot_gov']['session_check_delay']                       = '30'
default['login_dot_gov']['session_check_frequency']                   = '30'
default['login_dot_gov']['session_encryption_key']                    = 'change-this-immediately-with-rake-secret'
default['login_dot_gov']['session_timeout_in_minutes']                = '8'
default['login_dot_gov']['session_timeout_warning_seconds']           = '150'
default['login_dot_gov']['sha_revision']                              = ''
default['login_dot_gov']['smtp_settings']                             = '{"address":"smtp.mandrillapp.com", "port":587, "authentication":"login", "enable_starttls_auto":true, "user_name":"user@gmail.com","password":"xxx"}'
default['login_dot_gov']['stale_session_window']                      = '180'
default['login_dot_gov']['support_email']                             = 'hello@login.gov'
default['login_dot_gov']['support_url']                               = '/contact'
default['login_dot_gov']['twilio_accounts']                           = '[{"sid":"sid", "auth_token":"token", "number":"9999999999"}]'
default['login_dot_gov']['twilio_record_voice']                       = 'false'
default['login_dot_gov']['use_kms']                                   = 'false'
default['login_dot_gov']['valid_authn_contexts']                      = '["http://idmanagement.gov/ns/assurance/loa/1", "http://idmanagement.gov/ns/assurance/loa/3"]'
default['login_dot_gov']['release_dir']                               = ''
default['login_dot_gov']['sha_revision']                              = ''
default['login_dot_gov']['branch_name']                               = 'master'

# new relic
default['login_dot_gov']['agent_enabled']                             = 'true'
default['login_dot_gov']['app_name']                                  = 'login.gov'
default['login_dot_gov']['audit_log_enabled']                         = 'false'
default['login_dot_gov']['auto_instrument']                           = 'false'
default['login_dot_gov']['capture_error_source']                      = 'true'
default['login_dot_gov']['error_collector_enabled']                   = 'true'
default['login_dot_gov']['log_level']                                 = 'info'
default['login_dot_gov']['monitor_mode']                              = 'true'
default['login_dot_gov']['transaction_tracer_enabled']                = 'true'
default['login_dot_gov']['record_sql']                                = 'obfuscated'
default['login_dot_gov']['stack_trace_threshold']                     = '0.500'
default['login_dot_gov']['transaction_threshold']                     = 'apdex_f'

# sp-rails
default['login_dot_gov']['sp_rails']['http_auth_username'] = '<%= ENV["SP_NAME"] %>'
default['login_dot_gov']['sp_rails']['http_auth_password'] = '<%= ENV["SP_PASS"] %>'
default['login_dot_gov']['sp_rails']['idp_cert_fingerprint']= '8B:D5:C2:E8:9A:2B:CE:B7:4B:95:50:BA:16:79:05:27:17:D1:D3:67'
default['login_dot_gov']['sp_rails']['idp_slo_url'] = 'https://idp.<%= ENV["SAML_ENV"] %>.login.gov/api/saml/logout'
default['login_dot_gov']['sp_rails']['idp_sso_url'] = 'https://idp.<%= ENV["SAML_ENV"] %>.login.gov/api/saml/auth'
default['login_dot_gov']['sp_rails']['saml_issuer'] = 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:rails-<%= ENV["SAML_ENV"] %>'
default['login_dot_gov']['sp_rails']['secret_key_base'] = '<%= ENV["SECRET_KEY_BASE"] %>'
