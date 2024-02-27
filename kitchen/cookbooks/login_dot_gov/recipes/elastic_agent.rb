# I couldn't find any way to successfully provision and enroll the elastic
# agent in the base-image so we have to enroll it during the provision phase

base_path         = "common/soc_agents/elastic"
install_directory = '/root/elastic'
token             = ConfigLoader.load_config(node, "elastic_token", common: true)
url               = ConfigLoader.load_config(node, "elastic_url", common: true)
enroll_options    = "--enrollment-token=#{token} \
--force \
--proxy-url=http://obproxy.login.gov.internal:3128 \
--tag 'Q-LG' \
--url=#{url}"

execute 'enroll elastic agent' do
  command "elastic-agent enroll #{enroll_options}"
  ignore_failure true
  action :run
  sensitive true # hide elastic token
end
