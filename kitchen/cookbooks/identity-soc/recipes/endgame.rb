node.run_state['aws_region'] = Chef::Recipe::AwsMetadata.get_aws_region
node.run_state['aws_account_id'] = Chef::Recipe::AwsMetadata.get_aws_account_id
node.run_state['bucket'] = "login-gov.secrets.#{node.run_state['aws_account_id']}-#{node.run_state['aws_region']}"
node.run_state['endgame_config'] =  "SensorLinuxInstaller-Login.gov--Only--Sensor.cfg"
node.run_state['endgame_installer'] = "SensorLinuxInstaller-Login.gov--Only--Sensor"
# cannot use /var/tmp since the installer is an executable
node.run_state['install_directory'] = '/root/endgame'

# copy installer files
directory node.run_state['install_directory']
execute "aws s3 cp s3://#{node.run_state['bucket']}/common/endgame_apikey #{node.run_state['install_directory']}/"
execute "aws s3 cp s3://#{node.run_state['bucket']}/common/#{node.run_state['endgame_config']} #{node.run_state['install_directory']}/"
execute "aws s3 cp s3://#{node.run_state['bucket']}/common/#{node.run_state['endgame_installer']} #{node.run_state['install_directory']}/"

# make the endgame install executable
execute "chmod +x #{node.run_state['install_directory']}/#{node.run_state['endgame_installer']}"

# install agent
node.run_state['eg_exe'] = "#{node.run_state['install_directory']}/#{node.run_state['endgame_installer']}"
node.run_state['eg_config'] = "#{node.run_state['install_directory']}/#{node.run_state['endgame_config']}"
node.run_state['eg_log'] = "/var/log/endgame_install.log"

node.run_state['eg_options'] = "-l #{node.run_state['eg_log']} -d false -k $(cat #{node.run_state['install_directory']}/endgame_apikey) -c #{node.run_state['eg_config']}"
execute 'install endgame sensor' do
  command "#{node.run_state['eg_exe']} #{node.run_state['eg_options']}"
end
