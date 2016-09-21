#
# Cookbook Name:: login_dot_gov
# Attributes:: default
#
default['login_dot_gov']['admin_email']                     = 'justin.grevich@gsa.gov'
default['login_dot_gov']['app_names']                       = []
default['login_dot_gov']['dev_users']                       = []
default['login_dot_gov']['domain_name']                     = 'login.gov'
default['login_dot_gov']['rails_env']                       = 'production'
default['login_dot_gov']['ruby_version']                    = '2.3.1'
default['login_dot_gov']['system_user']                     = 'ubuntu'

# idp config
default['login_dot_gov']['allow_third_party_auth']          = 'yes'
default['login_dot_gov']['enable_test_routes']              = 'no'
default['login_dot_gov']['idp_sso_target_url']              = ''
default['login_dot_gov']['idv_attempt_window_in_hours']     = '24'
default['login_dot_gov']['idv_max_attempts']                = '3'
default['login_dot_gov']['logins_per_ip_limit']             = '20'
default['login_dot_gov']['logins_per_ip_period']            = '8'
default['login_dot_gov']['otp_delivery_blocklist_bantime']  = '10'
default['login_dot_gov']['otp_delivery_blocklist_findtime'] = '5'
default['login_dot_gov']['otp_delivery_blocklist_maxretry'] = '5'
default['login_dot_gov']['participate_in_dap']              = 'no'
default['login_dot_gov']['proofing_vendors']                = 'mock'
default['login_dot_gov']['pt_mode']                         = 'off'
default['login_dot_gov']['recovery_code_length']            = '16'
default['login_dot_gov']['requests_per_ip_limit']           = '300'
default['login_dot_gov']['requests_per_ip_period']          = '300'
default['login_dot_gov']['secret_token']                    = 'change-this-token-immediately-94017179907962f1f9a357dfaf2dd33f904b1ed4'
default['login_dot_gov']['session_check_delay']             = '30'
default['login_dot_gov']['session_check_frequency']         = '30'
default['login_dot_gov']['session_timeout_warning_in']      = '8'
default['login_dot_gov']['session_timeout_warning_seconds'] = '150'
default['login_dot_gov']['stale_session_window']            = '180'
default['login_dot_gov']['support_email']                   = 'hello@login.gov'
default['login_dot_gov']['support_url']                     = '/contact'
default['login_dot_gov']['valid_service_providers']         = '[]'
