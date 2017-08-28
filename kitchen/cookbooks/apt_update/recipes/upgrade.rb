#
# Cookbook Name:: apt_update
# Recipe:: upgrade

# for some reason logstash package doesnt respond well to force-yes , see 
# comments on https://github.com/18F/identity-devops/pull/369

dpkg_options = "apt-get  -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""

[ "upgrade -y","dist-upgrade -y"].each do |cmd|
  execute cmd do
    command "#{dpkg_options} " + cmd
    environment {'DEBIAN_FRONTEND' => 'noninteractive'}
  end
end
