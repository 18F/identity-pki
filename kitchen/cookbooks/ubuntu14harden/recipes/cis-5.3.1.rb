package 'libpam-pwquality'

template '/etc/security/pwquality.conf' do
    source 'pwquality.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  template '/etc/pam.d/common-password' do
    source 'common-password.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end