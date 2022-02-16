endgame_config =  "SensorLinuxInstaller-Login.gov--Only--Sensor.cfg"
endgame_installer = "SensorLinuxInstaller-Login.gov--Only--Sensor"

# cannot use /var/tmp since the installer is an executable
install_directory = '/root/endgame'

# install and register agent
eg_exe = "#{install_directory}/#{endgame_installer}"
eg_config = "#{install_directory}/#{endgame_config}"
eg_log = "/var/log/endgame_install.log"
eg_options = "-l #{eg_log} -d false -k $(cat #{install_directory}/endgame_apikey) -c #{eg_config}"

# note that we are backgrounding this task since it can take ~3 minutes to
# complete. This has been documented by the vendor and a fix has been promised
# in a future release.
execute 'install endgame sensor' do
  command "#{eg_exe} #{eg_options} &"
end
