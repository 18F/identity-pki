# download Slack hook/channel files for id-rails-console
%w(slackwebhook slackchannel).each do |f|
  file "/etc/login.gov/keys/#{f}" do
    content ConfigLoader.load_config(node, f, common:true)
  end
end

cookbook_file '/usr/local/bin/id-rails-console' do
  source 'id-rails-console'
  owner 'root'
  group 'root'
  mode '0755'
end
