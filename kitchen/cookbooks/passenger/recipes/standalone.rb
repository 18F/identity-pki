#
# Cookbook Name:: passenger
# Recipe:: development

include_recipe "passenger::install"

bash "starting passenger standalone" do
  user node[:passenger][:development][:run_as]
  only_if { node[:passenger][:development][:rack_application_path] }
  not_if "test -e /usr/local/rvm"
  code <<-EOH
    cd #{node[:passenger][:development][:rack_application_path]}
    passenger start --address #{node[:passenger][:development][:address]} \
      --port #{node[:passenger][:development][:port]} \
      --environment development
  EOH
end
