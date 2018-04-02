#
# Cookbook Name:: login_dot_gov
# Attributes:: default
#

# Set default provisioner to unknown.
#   On auto-scaled instances, this will be overridden by chef-attributes.json
#   from cloud-init.
#   On kitchen-ec2 test instances, this will be overridden by "attributes" in
#   kitchen.cloud.yaml.
default['provisioner']['name'] = 'unknown'
default['provisioner']['auto-scaled'] = false

default['login_dot_gov']['admin_email']                               = 'developer@login.gov'
default['login_dot_gov']['app_names']                                 = []
default['login_dot_gov']['dev_users']                                 = []
default['login_dot_gov']['rails_env']                                 = 'production'
default['login_dot_gov']['ruby_version']                              = '2.3.7'
default['login_dot_gov']['system_user']                               = 'ubuntu'
default['login_dot_gov']['fips']['version']                           = '2.0.16'
default['login_dot_gov']['fips']['url']                               = "https://www.openssl.org/source/openssl-fips-#{default['login_dot_gov']['fips']['version']}.tar.gz"
default['login_dot_gov']['fips']['checksum']                          = 'a3cd13d0521d22dd939063d3b4a0d4ce24494374b91408a05bdaca8b681c63d4'
default['login_dot_gov']['openssl']['version']                        = '1.0.2o'
default['login_dot_gov']['openssl']['prefix']                         = "/opt/openssl-#{default['login_dot_gov']['openssl']['version']}"
default['login_dot_gov']['openssl']['url']                            = "https://www.openssl.org/source/openssl-#{default['login_dot_gov']['openssl']['version']}.tar.gz"
default['login_dot_gov']['openssl']['checksum']                       = 'ec3f5c9714ba0fd45cb4e087301eb1336c317e0d20b575a125050470e8089e4d'
default['login_dot_gov']['openssl']['configure_flags']                = %W[ shared ]

default['login_dot_gov']['cache_dir']                                 = '/var/cache/chef'

# Allocate a static EIP on startup for auto scaled instances that have one of
# these as their primary role (e.g. 'worker', 'jumphost').
# The instance run list must also include the login_dot_gov::static_eip recipe.
default['login_dot_gov']['auto_eip_enabled_roles'] = []

# The gitref that we check out when deploying
default['login_dot_gov']['gitref']                          = 'master'

# used to turn off app startup and migrations and other things so that we can
# run idp_base to generate a mostly-populated AMI with packer
default['login_dot_gov']['setup_only']                                = false

# idp config
case Chef::Recipe::AwsMetadata.get_aws_account_id
when /\A55554/
  default['login_dot_gov']['domain_name'] = 'login.gov'
when /\A89494/
  default['login_dot_gov']['domain_name'] = 'identitysandbox.gov'
else
  raise "Unexpected AWS account ID: #{Chef::Recipe::AwsMetadata.get_aws_account_id.inspect}"
end
default['login_dot_gov']['release_dir']                               = ''
default['login_dot_gov']['sha_revision']                              = ''
default['login_dot_gov']['sslrootcert']                               = '/usr/local/share/aws/rds-combined-ca-bundle.pem'
default['login_dot_gov']['branch_name']                               = 'master'

# new relic
default['login_dot_gov']['agent_enabled']                             = true
default['login_dot_gov']['app_name']                                  = 'login.gov'
default['login_dot_gov']['audit_log_enabled']                         = false
default['login_dot_gov']['auto_instrument']                           = false
default['login_dot_gov']['capture_error_source']                      = true
default['login_dot_gov']['error_collector_enabled']                   = true
default['login_dot_gov']['log_level']                                 = 'info'
default['login_dot_gov']['monitor_mode']                              = true
default['login_dot_gov']['transaction_tracer_enabled']                = true
default['login_dot_gov']['record_sql']                                = 'obfuscated'
default['login_dot_gov']['stack_trace_threshold']                     = 0.500
default['login_dot_gov']['transaction_threshold']                     = 'apdex_f'
default['login_dot_gov']['proxy_addr']                                = nil
default['login_dot_gov']['proxy_port']                                = nil

# sp-rails
# 0b:83... is the fingerprint of the SAML IDP cert CN=int.login.gov
# Serial: fc:5d:1e:d8:a3:3b:57:ed
#            Not Before: Mar  8 20:49:06 2018 GMT
#            Not After : Apr  1 20:49:06 2019 GMT
# TODO: don't hardcode this
default['login_dot_gov']['sp_rails']['idp_cert_fingerprint'] = '0B:83:73:2F:6D:57:3B:F0:CF:09:79:9D:69:6C:9B:93:34:52:80:2A'
default['login_dot_gov']['sp_rails']['saml_issuer'] = "urn:gov:gsa:SAML:2.0.profiles:sp:sso:rails-#{node.chef_environment}"

# dashboard
default['login_dot_gov']['dashboard']['sp_certificate']               = "-----BEGIN CERTIFICATE-----\nMIIFLjCCAxYCCQD/dXjTvpnD0jANBgkqhkiG9w0BAQsFADBZMQswCQYDVQQGEwJV\nUzETMBEGA1UECBMKV2FzaGluZ3RvbjELMAkGA1UEBxMCREMxDDAKBgNVBAoTAzE4\nRjEaMBgGA1UEAxMRdGVzdC5jZXJ0LjE4Zi5nb3YwHhcNMTYwNTEzMTUyNTE3WhcN\nMjYwNTExMTUyNTE3WjBZMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv\nbjELMAkGA1UEBxMCREMxDDAKBgNVBAoTAzE4RjEaMBgGA1UEAxMRdGVzdC5jZXJ0\nLjE4Zi5nb3YwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC+mkS5cTDx\nVgt36ad8/ssFvpO8KJhIlfc73pNdr4WDdnLp7935clx3RfRwjfENanTrotg/i4Oz\nDvLQvODj7GwD1nTozCPAw6wX4JOEbkN8IhnhdvxjePxxYWjZCbmsaLW2US9zBNcY\n+93qbBsSLN99Xw/wIKLGXxxgAGg0QO/706/M7dxGFENK+6a74pGkTEI/Zv82KBbr\nvTDfnkvVfR7TtoKGf9RKrtM/90BaLKpoV0SXMAc6Krw9ltk3DvJ5WKF5Q9KgkG2q\nQ2iGYmZEp1m/0LUd8a1DJUuqWqtm9j+8B69mHfcmf0FftdnlX+qfnQ1aPrBQTpFG\n+N1mj8at+ZCXy+IbyMf8BR+1k9YJeEAUVn/dg7jjVKTepM+IaC7C4rME+L2R+7X0\n1QvMDeJGHMJAmatV8FICKpPBq6F/3Ub86wLqzJNsK4fcpEf3jRwp9FclOGORtpVo\nE0VmGs+fIqP230FT1aRkNvNEfRFWi/9U8hUMvQAXI6jZKt++ScMMeLpqvjR5HrRC\n+d7w9MvJ7XZDu3IRV8gdH7KYwX6xIdqKboCw9wcXn3kREDL6cNqs5l/VN74Qx4yg\ni/aRabwd/d4CTSkq9kpngb5AaVESkd+fCu40+FznkxCE59qKMrjYDFYnuYUmPceH\n9kgYgaD/8ARPkmHnPoXT3bLzlOtTtqqJswIDAQABMA0GCSqGSIb3DQEBCwUAA4IC\nAQCfLLqCR2jQFbvK/KxNbDeDh0EkGC96+/3i6XWFS9EeJcU3/pDYBi5aLTkRcAsN\n31heZ8ThRWN6/ZwsIrhQi0rqp1FB0OvTjMI5u1MTxFL/88ftk7fkll6wTN9HZZcr\n7wVVSa37ULN9HmBaxXFKzBxo+RRDrucD+hk8dUBOlMf3FI+HlDLBYt5bn+TA5rvB\ny5KbEn+ryhCAUf+byghkR/r20bh6WNRw27TvO0ocyMTLXqXpr0YKnT3E2KVjABmE\nWLHFbJRv7WD3MhB+dgJhpIZuDkijsDT7ns/lO7jXdzcpVFZ9C09HlVam8G0L6//0\n5qexSv2xW2/oeJULok2FFOsYdIWgWlhscg5GKHkZ5EZo50AMWTuVFT7vw/SLzus1\n7HgmM03IjSxCr6Kl1rp022x+SBrMLTvHLSRqeM26HvNGGKX7N0R0/xAXJ6oqQPLg\n6YbAQvI7oxdCKZFNUE9ZMhT34F84ZRMwQluzeukiMne1Z/ZZX317cKOEflZiU3mc\n7nZHi2STJiL0mD8A3laPPgegeNmuEnDPYOo+sMgyan8scJR8vUIQEKACnkHNoa8G\n3xQBe08Bt1P/kcAGC3awQUqEnFVx6ORD0QWpPpaWe/0SO4mb2DwyGeBcCI027qVA\n6czR3hR8eGhocSy2VSoSymE2DlBF/Jt5Pwa8SzSHw/5/8g==\n-----END CERTIFICATE-----"
default['login_dot_gov']['dashboard']['sp_private_key']               = "-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED\nDEK-Info: DES-EDE3-CBC,3BBA2AE203104123\n\n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\n-----END RSA PRIVATE KEY-----"
default['login_dot_gov']['dashboard']['sp_private_key_password']      = 'foobar'

# 0B:83:... is the fingerprint of the SAML IDP cert CN=int.login.gov
# Serial: fc:5d:1e:d8:a3:3b:57:ed
#            Not Before: Mar  8 20:49:06 2018 GMT
#            Not After : Apr  1 20:49:06 2019 GMT
# TODO: don't hardcode this
default['login_dot_gov']['dashboard']['idp_cert_fingerprint']         = '0B:83:73:2F:6D:57:3B:F0:CF:09:79:9D:69:6C:9B:93:34:52:80:2A'
