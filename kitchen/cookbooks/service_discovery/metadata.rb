name 'service_discovery'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'All Rights Reserved'
description 'Installs/Configures service_discovery'
long_description 'Installs/Configures service_discovery'
version '0.2.1'
chef_version '>= 12.15.19' if respond_to?(:chef_version)

gem 'aws-sdk-ec2', '~> 1.0'

depends 'aws_metadata'
depends 'aws_s3'
depends 'canonical_hostname'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/service_discovery/issues'

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/service_discovery'
