# install dependencies
# TODO: JJG convert to platform agnostic way of installing packages to avoid case statement(s)
case
when platform_family?('rhel')
  ['cyrus-sasl-devel',
   'libtool-ltdl-devel',
   'postgresql-devel',
   'ruby-devel'].each { |pkg| package pkg }
when platform_family?('debian')
  ['libpq-dev',
   'libsasl2-dev',
   'ruby-dev'].each { |pkg| package pkg }
end

ENV['TMPDIR'] = '/usr/local/src' # mv due to noexec on /tmp mountpoint
execute "chown -R #{node['login_dot_gov']['system_user']}: /usr/local/src"

deploy '/srv/idp' do
  action :deploy
  before_symlink do
    cmd = "bundle install --deployment --jobs 4 --path /srv/idp/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      environment 'TMPDIR' => "/usr/local/src"
      user 'ubuntu'
    end
  end
  repo 'https://github.com/18F/identity-idp.git'
  symlinks ({
    "system" => "public/system",
    "pids" => "tmp/pids",
    "log" => "log",
    'bundle' => '.bundle'
  })
  user 'ubuntu'
end

package 'monit'
service 'monit'

template '/etc/monit/monitrc' do
  mode '0700'
  notifies :restart, "service[monit]"
end
