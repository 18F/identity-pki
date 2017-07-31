name 'aws_s3'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'All Rights Reserved'
description 'Installs/Configures aws_s3'
long_description 'Installs/Configures aws_s3'
version '0.1.0'
chef_version '>= 12.15.19' if respond_to?(:chef_version)

gem 'aws-sdk'

depends 'aws_metadata'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/aws_s3/issues'

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/aws_s3'
