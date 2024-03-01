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

# create systemD overrides to prevent agent/endpoint from consuming too many resources
['elastic-agent', 'ElasticEndpoint'].each do |service|
  directory "/etc/systemd/system/#{service}.service.d"
  
  cookbook_file "/etc/systemd/system/#{service}.service.d/override.conf" do
    source 'systemd_override.conf'
  end
end

execute 'reload daemon for elastic service updates' do
  command 'systemctl daemon-reload'
end

execute 'enroll elastic agent' do
  command "elastic-agent enroll #{enroll_options}"
  ignore_failure true
  action :run
  sensitive true # hide elastic token
end
