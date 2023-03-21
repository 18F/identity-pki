# Domain on which to request a wildcard cert.
default['pivcac']['domain'] = "pivcac.#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"
# The actual wildcard.
default['pivcac']['wildcard'] = "*.#{node.fetch('pivcac').fetch('domain')}"

# S3 bucket in which we store SSL certs. It would be nice if this could be
# shared with Terraform.
default['pivcac']['bucket'] = "login-gov-pivcac-#{node.chef_environment}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"

default['pivcac']['letsencrypt_bundle'] = "letsencrypt.#{node.chef_environment}.tar.gz"
default['pivcac']['temporary_bundle_path'] = "/root/#{node.fetch('pivcac').fetch('letsencrypt_bundle')}"

default['pivcac']['letsencrypt_email'] = 'identity-devops@login.gov'
default['pivcac']['letsencrypt_use_staging'] = false # for testing
default['pivcac']['letsencrypt_path'] = '/etc/letsencrypt'
default['pivcac']['letsencrypt_preferred'] = "ISRG Root X1"
default['pivcac']['letsencrypt_key_type'] = "rsa"

default['pivcac']['chef_zero_client_configuration'] = '/etc/login.gov/repos/identity-devops/kitchen/chef-client.rb'
