log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '/root/admin.pem'
validation_client_name   'login-dev-validator'
validation_key           '/root/login-dev-validator.pem'
chef_server_url          'https://chef.login.gov.internal/organizations/login-dev'
syntax_check_cache_path  '/root/.chef/syntax_check_cache'

cache_options path: "#{ENV['HOME']}/.chef/checksums"
cookbook_path [
  "./kitchen/cookbooks"
]

