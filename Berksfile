source 'https://api.berkshelf.com'

cookbook 'apt', '~> 7.0'
cookbook 'bash-completion'
cookbook 'cacert'
cookbook 'deploy_resource', '~> 1.0'
cookbook 'git'
cookbook 'letsencrypt', '~> 1.0.0'
cookbook 'motd'
cookbook 'openssl'
cookbook 'ssh-keys'
cookbook 'sudo'
cookbook 'users'
cookbook 'ossec', '~> 1.2.0', git: 'https://github.com/sous-chefs/ossec'
cookbook 'seven_zip', '~3.2.0' #can remove version constraint after upgrading chef to v16
cookbook 'filesystem', '~> 3.0.5'

# This is a super wacky hack to allow us to symlink this Berksfile into the
# various nodes/*/ directories. It feels like there ought to be a better way to
# do this, e.g. by running `berks -b ../../Berksfile` from test-kitchen, but I
# wasn't able to figure one out.
def prefixed(path)
  unless @prefix
    if File.symlink?(__FILE__)
      # if we're a symlink, figure out the path diff to get to the target
      @prefix = File.dirname(File.readlink(__FILE__))
    else
      @prefix = '.'
    end
  end

  @prefix + '/' + path
end

# Vendored cookbooks. This should include everything in kitchen/cookbooks except for cookbook_example
cookbook 'identity-outboundproxy', path: prefixed('kitchen/cookbooks/identity-outboundproxy')
cookbook 'aws_s3', path: prefixed('kitchen/cookbooks/aws_s3')
cookbook 'canonical_hostname', path: prefixed('kitchen/cookbooks/canonical_hostname')
cookbook 'chef_proxy_env', path: prefixed('kitchen/cookbooks/chef_proxy_env')
cookbook 'identity-gitlab', path: prefixed('kitchen/cookbooks/identity-gitlab')
cookbook 'identity-jumphost', path: prefixed('kitchen/cookbooks/identity-jumphost')
cookbook 'identity-nessus', path: prefixed('kitchen/cookbooks/identity-nessus')
cookbook 'identity-pivcac', path: prefixed('kitchen/cookbooks/identity-pivcac')
cookbook 'instance_certificate', path: prefixed('kitchen/cookbooks/instance_certificate')
cookbook 'login_dot_gov', path: prefixed('kitchen/cookbooks/login_dot_gov')
cookbook 'service_discovery', path: prefixed('kitchen/cookbooks/service_discovery')
cookbook 'identity-monitoring', path: prefixed('kitchen/cookbooks/identity-monitoring')

# Cookbooks from our open source github repo
# When updating this gitref, you MUST also run `berks update` and commit
# the changes to Berksfile.lock. Otherwise the old gitref will continue to be
# used by Chef.
IdentityCookbooksRef = '879b902bd5ca66487922e34a85c217a41728f668'
cookbook 'aws_metadata', '>= 0.3.0', git: 'https://github.com/18F/identity-cookbooks', rel: 'aws_metadata', ref: IdentityCookbooksRef
cookbook 'config_loader', '>= 0.2.2', git: 'https://github.com/18F/identity-cookbooks', rel: 'config_loader', ref: IdentityCookbooksRef
cookbook 'identity_base_config', '>= 0.1.2', git: 'https://github.com/18F/identity-cookbooks', rel: 'identity_base_config', ref: IdentityCookbooksRef
cookbook 'identity_shared_attributes', '>= 0.1.2', git: 'https://github.com/18F/identity-cookbooks', rel: 'identity_shared_attributes', ref: IdentityCookbooksRef
cookbook 'static_eip', '>= 0.2.1', git: 'https://github.com/18F/identity-cookbooks', rel: 'static_eip', ref: IdentityCookbooksRef

# We have to reference this special citadel-build repository for two reasons:
#
# 1. We have a custom fork of https://github.com/poise/citadel at
#    https://github.com/18f/citadel.git because of
#    https://github.com/poise/citadel/pull/35 and
#    https://github.com/poise/citadel/pull/36.
# 2. There is an extra build step required, and the citadel repository itself is
#    a valid cookbook.  See the citadel-build repository for more details.  This
#    worked before without this extra repo because we were pulling the built
#    citadel from https://supermarket.chef.io.
#
# Once the pull requests are merged and a new citadel version is released we can
# get rid of this.
