resource_name :basic_auth_config

property :name, String, default: 'generate basic auth config'
property :user_name, String, default: '18f'
property :password, String, default: 'Zero-Inconvenience'
property :location, String, default: '/opt/nginx/conf'
property :filename, String, default: 'htpasswd'

action :create do
  execute "generate basic auth config" do
    # see: https://httpd.apache.org/docs/2.4/misc/password_encryptions.html
    command "echo \"#{user_name}:\"`openssl passwd -apr1 #{password}` > #{location}/htpasswd"
    subscribes :start, "service[passenger]", :before
    subscribes :restart, "service[passenger]", :before
    subscribes :reload, "service[passenger]", :before
  end
end
