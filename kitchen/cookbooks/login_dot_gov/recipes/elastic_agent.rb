# I couldn't find any way to successfully provision and enroll the elastic
# agent in the base-image so we have to enroll it during the provision phase

proxy_flag   = ''
primary_role = File.read('/etc/login.gov/info/role').chomp

if primary_role != 'outboundproxy'
  proxy_flag = '--proxy-url=http://obproxy.login.gov.internal:3128'
end

base_path         = "common/soc_agents/elastic"
install_directory = '/root/elastic'
token             = ConfigLoader.load_config(node, "elastic_token", common: true)
url               = ConfigLoader.load_config(node, "elastic_url", common: true)
enroll_options    = "--enrollment-token=#{token} \
--force \
--tag 'Q-LG' \
--url=#{url} #{proxy_flag}"

execute 'enroll elastic agent' do
  command "elastic-agent enroll #{enroll_options}"
  ignore_failure true
  action :run
  sensitive true # hide elastic token
end
