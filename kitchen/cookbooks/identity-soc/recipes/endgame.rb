aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
bucket = "login-gov.secrets.#{aws_account_id}-#{aws_region}"
endgame_config =  "SensorLinuxInstaller-Login.gov--Only--Sensor.cfg"
endgame_installer = "SensorLinuxInstaller-Login.gov--Only--Sensor"
# cannot use /var/tmp since the installer is an executable
install_directory = '/root/endgame'

# copy installer files
directory install_directory
execute "aws s3 cp s3://#{bucket}/common/endgame_apikey #{install_directory}/"
execute "aws s3 cp s3://#{bucket}/common/#{endgame_config} #{install_directory}/"
execute "aws s3 cp s3://#{bucket}/common/#{endgame_installer} #{install_directory}/"

# make the endgame install executable
execute "chmod +x #{install_directory}/#{endgame_installer}"

# install agent
eg_exe = "#{install_directory}/#{endgame_installer}"
eg_config = "#{install_directory}/#{endgame_config}"
eg_log = "/var/log/endgame_install.log"

eg_options = "-l #{eg_log} -d false -k $(cat #{install_directory}/endgame_apikey) -c #{eg_config}"
execute 'install endgame sensor' do
  command "#{eg_exe} #{eg_options}"
end
