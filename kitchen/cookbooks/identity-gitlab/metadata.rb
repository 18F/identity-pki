name             'identity-gitlab'
maintainer       '18f identity'
maintainer_email 'developer@login.gov'
license          'GNU Public License 3.0'
description      'Installs/Configures identity-gitlab'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.5'

depends 'config_loader'
depends 'filesystem'
depends 'docker'
depends	'login_dot_gov'
depends 'packagecloud'
