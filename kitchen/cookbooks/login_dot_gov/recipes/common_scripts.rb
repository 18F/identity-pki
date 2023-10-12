# download Slack hook/channel files for id-rails-console
%w(slackwebhook slackchannel).each do |f|
  file "/etc/login.gov/keys/#{f}" do
    content ConfigLoader.load_config(node, f)
  end
end

template '/usr/local/bin/id-rails-console' do
  source 'id-rails-console'
  owner 'root'
  group 'root'
  mode '0755'
end

template '/usr/local/bin/notify-slack' do
  source 'notify-slack'
  owner 'root'
  group 'root'
  mode '0755'
end
