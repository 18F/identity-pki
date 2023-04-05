#
# Cookbook Name:: identity-gitlab
# Attributes:: default
#

# turn on image signing verification if this is true
default['identity_gitlab']['image_signing_verification'] = false
# This is the name of the image signing pubkey in the secrets bucket.
default['identity_gitlab']['image_signing_pubkey'] = 'image_signing.pub'
# This allows you to select whether the signing pubkey is in the common bucket
# or in the env bucket.
default['identity_gitlab']['image_signing_pubkey_common'] = true
