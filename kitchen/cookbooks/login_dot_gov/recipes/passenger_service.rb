# replacement for passenger recipe
# passenger is built as part of base image

native_support_dir = node.fetch(:passenger).fetch(:production).fetch(:path) + '/passenger-native-support'

# Any value of RUBY_YJIT_ENABLE will enable it, even false, so we have to avoid including the ENV
# variable if we do not want to enable it.
ruby_yjit = node.fetch('login_dot_gov').fetch('idp_ruby_yjit_enabled')

file '/etc/default/passenger' do
  content <<-EOM
export http_proxy=#{Chef::Config['http_proxy']}
export https_proxy=#{Chef::Config['https_proxy']}
export no_proxy=#{Chef::Config['no_proxy']}
#{ruby_yjit == true || ruby_yjit == 'true' ? "export RUBY_YJIT_ENABLE='true'" : ""}
export PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR='#{native_support_dir}'
  EOM
end

service 'passenger' do
  action :nothing
  supports restart: true, status: true
end
