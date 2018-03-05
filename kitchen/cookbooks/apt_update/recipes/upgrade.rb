#
# Cookbook Name:: apt_update
# Recipe:: upgrade

# for some reason logstash package doesnt respond well to force-yes , see 
# comments on https://github.com/18F/identity-devops/pull/369

dpkg_options = "DEBIAN_FRONTEND=noninteractive apt-get  -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""

[ "upgrade -y","dist-upgrade -y"].each do |cmd|
  execute cmd do
    retries 2
    command "#{dpkg_options} " + cmd
  end
end
