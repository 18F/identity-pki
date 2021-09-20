#replacement for passenger recipe
#passenger is built as part of base image

native_support_dir = node.fetch(:passenger).fetch(:production).fetch(:path) + '/passenger-native-support'

file "/etc/default/passenger" do
  content <<-EOM
export http_proxy=#{Chef::Config['http_proxy']}
export https_proxy=#{Chef::Config['https_proxy']}
export no_proxy=#{Chef::Config['no_proxy']}
export PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR='#{native_support_dir}'
  EOM
end


service 'passenger' do
    action :nothing
    supports restart: true, status: true
end
