# assure that we're working with an updated package list in case anything is
# yanked between the time the image is built and an instance is provisioned.

execute 'apt-get -o DPkg::Lock::Timeout=240 update'

# enable ESM and then re-run apt update
package 'ubuntu-advantage-tools' do
  options '-o DPkg::Lock::Timeout=240'
end

execute 'ubuntu_advantage_set_news' do
  command <<-EOF
    if [ "`sudo ua status --format=json | jq -r '.config.ua_config.apt_news'`" == true ]; then
        sudo pro config set apt_news=false 
    fi
  EOF
  ignore_failure false
  action :run
end

execute 'pro refresh config' do
  ignore_failure true
  action :run
end

execute 'ubuntu_advantage_esm_apps' do
  command <<-EOF
    if [ "`sudo ua status --format=json | jq -r '.services[] | select(.name=="esm-apps") | .status'`" == disabled ]; then
        sudo ua enable esm-apps --assume-yes 
    fi
  EOF
  ignore_failure false
  action :run
end

execute 'apt update' do
  only_if { node.fetch('login_dot_gov').fetch('run_apt_update') }
end
