# download Slack hook/channel files for id-rails-console
%w(slackwebhook slackchannel).each do |f|
  file "/etc/login.gov/keys/#{f}" do
    content ConfigLoader.load_config(node, f)
  end
end

template '/usr/local/bin/id-rails-console' do
  source 'id-cmd.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables ({
    rails_console: true,
    rails_task:    'console',
    script_name:   'id-rails-console',
    slack_icon:    'dopetopus'
  })
end

template '/usr/local/bin/id-uuid-lookup' do
  source 'id-cmd.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables ({
    rails_console: false,
    rails_task:    'users:lookup_by_email',
    script_name:   'id-uuid-lookup',
    slack_icon:    'mag'
  })
end
