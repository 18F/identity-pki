# Install Node.js from nodesource apt repo
# Install Yarn from Yarn apt repo
#
# TODO: it would probably be better for security to copy these packages into
# hosting in our own infrastructure somewhere so we have an audit record of
# what bits were actually installed. Aptly https://www.aptly.info/ looks like a
# really good tool for doing this.

apt_package 'nodejs' do
  action :upgrade
end

apt_package 'yarn' do
  action :upgrade
end
