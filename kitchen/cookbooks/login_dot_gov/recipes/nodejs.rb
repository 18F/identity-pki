# Install Node.js from nodesource apt repo
# Install Yarn from Yarn apt repo
#
# TODO: it would probably be better for security to copy these packages into
# hosting in our own infrastructure somewhere so we have an audit record of
# what bits were actually installed. Aptly https://www.aptly.info/ looks like a
# really good tool for doing this.

node_version = '8.x'

apt_package 'apt-transport-https'

# https://deb.nodesource.com/gpgkey/nodesource.gpg.key
# GPG key 9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280
cookbook_file '/etc/apt/trusted.gpg.d/nodesource.gpg' do
  source 'apt/trusted.gpg.d/nodesource.gpg'
  sensitive true # not secret, but useless for humans
end

apt_repository 'nodesource' do
  uri "https://deb.nodesource.com/node_#{node_version}"
  distribution node.fetch('lsb').fetch('codename')
  components ['main']
  deb_src true
end

apt_package 'nodejs' do
  action :upgrade
end

# Install the Yarn package manager, a faster and more secure alternative to npm

# https://dl.yarnpkg.com/debian/pubkey.gpg
# GPG key 72ECF46A56B4AD39C907BBB71646B01B86E50310
cookbook_file '/etc/apt/trusted.gpg.d/yarnpkg.gpg' do
  source 'apt/trusted.gpg.d/yarnpkg.gpg'
  sensitive true # not secret, but useless for humans
end

apt_repository 'yarnpkg' do
  uri 'https://dl.yarnpkg.com/debian/'
  distribution 'stable'
  components ['main']
end

apt_package 'yarn'
