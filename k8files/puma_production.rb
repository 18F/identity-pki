threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
threads threads_count, threads_count
environment ENV.fetch('RAILS_ENV') { 'production' }
app_dir = "/app"
shared_dir = "#{app_dir}/shared"

bind "unix://#{app_dir}/tmp/sockets/puma.sock"

stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"


set_remote_address proxy_protocol: :v1
bind "ssl://0.0.0.0:3001?key=/etc/letsencrypt/live/pivcac.identitysandbox.gov/privkey.pem&cert=/etc/letsencrypt/live/pivcac.identitysandbox.gov/fullchain.pem"
