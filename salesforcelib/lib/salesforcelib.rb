# Single point of entry for salesforcelib

# silence warnings from multipart-post until we can upgrade faraday
require 'warning'
Warning.ignore(%r|multipart/post|)

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'salesforcelib/auth'
require 'salesforcelib/client'
require 'salesforcelib/server'
require 'salesforcelib/ssm_config_loader'
require 'salesforcelib/keychain_config'
