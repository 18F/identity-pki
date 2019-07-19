# `chef_proxy_env`

This cookbook provides a single default recipe that allows setting Chef and ENV
proxy configuration based on values set in config files placed in a known
location.

This is useful to be able to set uniform proxy configuration. Normally you
would just set these in chef-client.rb, but when using test kitchen (e.g.
kitchen-ec2), Test Kitchen generates the chef-client.rb and there appears to be
no way to pass in custom values like proxy configuration.

Sets `ENV['http_proxy']` and `Chef::Config.http_proxy` for each of
`http_proxy`, `https_proxy`, and `no_proxy`.

