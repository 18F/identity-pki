name             'identity-jenkins'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures identity-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.8'

depends		'acme'
depends		'apache2'
depends		'jenkins'
depends		'ssh_known_hosts'
depends		'terraform'
depends		'login_dot_gov'
