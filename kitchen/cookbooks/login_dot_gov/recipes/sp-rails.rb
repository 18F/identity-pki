login_dot_gov_lets_encrypt 'sp'

deploy '/srv/sp-rails' do
  action :deploy
  before_symlink do
    cmd = "sudo bundle install --deployment --jobs 3 --path /srv/sp-rails/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      user 'ubuntu'
    end
  end
  repo 'https://github.com/18F/identity-sp-rails.git'
  symlinks ({
    "system" => "public/system",
    "pids" => "tmp/pids",
    "log" => "log",
    'bundle' => '.bundle'
  })
  user 'ubuntu'
end


