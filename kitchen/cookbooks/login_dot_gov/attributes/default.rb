#
# Cookbook Name:: login_dot_gov
# Attributes:: default
#
default['login_dot_gov']['ruby_version']                    = '2.3.1'
default['login_dot_gov']['rails_env']                       = 'production'
default['login_dot_gov']['system_user']                     = 'ubuntu'
default['login_dot_gov']['domain_name']                     = 'login.gov'
default['login_dot_gov']['admin_email']                     = 'justin.grevich@gsa.gov'
default['login_dot_gov']['dev_users']                       = []


# 3rd party config + keys
default['login_dot_gov']['google_analytics_key']            = nil
default['login_dot_gov']['newrelic_license_key']            = nil
default['login_dot_gov']['secret_token']                    = 'change-this-token-immediately-94017179907962f1f9a357dfaf2dd33f904b1ed4'
default['login_dot_gov']['application.yml']                 = nil
default['login_dot_gov']['saml_passphrase']                 = nil
default['login_dot_gov']['saml.key.enc']                    = nil
default['login_dot_gov']['app_names']                       = []

default['login_dot_gov']['db_database']                     = nil
default['login_dot_gov']['db_host']                         = nil
default['login_dot_gov']['db_password']                     = nil
default['login_dot_gov']['db_username']                     = nil
