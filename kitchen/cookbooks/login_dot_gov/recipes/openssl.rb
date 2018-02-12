# thanks to https://github.com/asynchrony/chef-openssl-fips for the blunt of the work

cache_dir = node.fetch('login_dot_gov').fetch('cache_dir')
directory cache_dir do
  action :create
end

src_dirpath  = "#{cache_dir}/openssl-fips-#{node['login_dot_gov']['fips']['version']}"
src_filepath  = "#{src_dirpath}.tar.gz"

remote_file node['login_dot_gov']['fips']['url'] do
  source node['login_dot_gov']['fips']['url']
  checksum node['login_dot_gov']['fips']['checksum']
  path src_filepath
  backup false
end

execute 'unarchive_fips' do
  cwd ::File.dirname(src_filepath)
  command <<-EOH
    tar zxf #{::File.basename(src_filepath)} -C #{::File.dirname(src_filepath)}
  EOH
  not_if { ::File.directory?(src_dirpath) }
end

fips_dirpath = "#{cache_dir}/openssl-fipsmodule-#{node['login_dot_gov']['fips']['version']}"

execute 'compile_fips_source' do
  cwd src_dirpath
  command <<-EOH
    ./config --prefix=#{fips_dirpath} && make && make install
  EOH
  not_if { ::File.directory?(fips_dirpath) }
end

src_dirpath = "#{cache_dir}/openssl-#{node['login_dot_gov']['openssl']['version']}"
src_filepath = "#{src_dirpath}.tar.gz"
remote_file node['login_dot_gov']['openssl']['url'] do
  source node['login_dot_gov']['openssl']['url']
  checksum node['login_dot_gov']['openssl']['checksum']
  path src_filepath
  backup false
end

execute 'unarchive_openssl' do
  cwd ::File.dirname(src_filepath)
  command "tar zxf #{::File.basename(src_filepath)} -C #{::File.dirname(src_filepath)}"
  not_if { ::File.directory?(src_dirpath) }
end

configure_flags = node['login_dot_gov']['openssl']['configure_flags'].map { |x| x }
configure_flags << "--prefix=#{node['login_dot_gov']['openssl']['prefix']}"
configure_flags << "fips" << "--with-fipsdir=#{fips_dirpath}"

execute 'compile_openssl_source' do
  cwd  src_dirpath
  command "./config #{configure_flags.join(' ')} && make && make install"
  not_if { ::File.directory?(node['login_dot_gov']['openssl']['prefix']) }
end
