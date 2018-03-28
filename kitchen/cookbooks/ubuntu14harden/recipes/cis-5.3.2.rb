  template '/etc/pam.d/common-auth' do
    source 'common-auth.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end