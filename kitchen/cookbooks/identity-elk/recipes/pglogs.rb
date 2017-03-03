# This cookbook installs a tool to slurp down logs from the RDS postgres instance

gem_package 'aws-sdk'

template '/usr/local/bin/getpglogs.rb' do
  source 'getpglogs.rb.erb'
  mode '0755'
  variables ({
    :region => node['ec2']['placement_availability_zone'].gsub(/[a-z]$/,''),
    :pglogdir => node['elk']['pglogsdir'],
    :env => node.chef_environment
  })
end

cron_d 'getpglogs' do
  minute 10
  command '/usr/local/bin/getpglogs.rb'
end

# make sure we clean up the pglogs dir
cron_d 'cleanpglogs' do
  minute 0
  hour 5
  command "find #{node['elk']['pglogsdir']} -type f -mtime +10 | xargs rm"
end

