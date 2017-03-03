name             'identity-elk'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures identity-elk'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.9'

depends          'java'
depends          'elasticsearch'
depends          'filebeat'
depends          'runit'
depends          'elasticsearch-curator'
depends          'acme'
depends          'apache2'
depends          'login_dot_gov'
depends          'cron'

