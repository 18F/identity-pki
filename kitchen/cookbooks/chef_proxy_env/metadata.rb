name 'chef_proxy_env'
maintainer 'Login.gov'
maintainer_email 'andrew.brody@gsa.gov'
license 'All Rights Reserved'
description 'Sets Chef proxy configuration using config in files'
long_description 'This is useful for setting uniform proxy configuration regardless of how chef-client.rb is generated.'
version '0.1.1'
chef_version '>= 12.15.19' if respond_to?(:chef_version)

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/chef_proxy_env/issues'

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/chef_proxy_env'
