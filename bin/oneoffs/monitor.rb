#!/usr/bin/env ruby

require 'rest-client'

def healthcheck_for_env(env:, domain:)
  if env == 'prod'
    "https://secure.#{domain}/api/health"
  else
    "https://idp.#{env}.#{domain}/api/health"
  end
end

def hit_db_healthcheck(url:)
  begin
    RestClient.get(url)
  rescue RestClient::ExceptionWithResponse => err
    err.response
  end
end

def monitor(env, interval: 2, domain: 'login.gov')
  url = healthcheck_for_env(env: env, domain: domain)
  STDERR.puts "Running health checks every #{interval} sec against #{url}"

  results = []
  loop do
    row = [Time.now, hit_db_healthcheck(url: url)]
    results << row

    puts "#{row.first}: #{row.last.code} #{row.last.net_http_res.msg}"
    sleep interval
  end
rescue Interrupt
  return results
end

def main
  if ARGV.empty?
    STDERR.puts <<-EOM
usage: #{File.basename($0)} ENV [DOMAIN]"

Run a healthcheck against https://idp.ENV.DOMAIN/api/health every 2 seconds.

For more complex usage, open this script in a repl, for example:
    pry -r $0
    >> monitor('dev', interval: 10, domain: 'identitysandbox.gov')
    EOM
    exit 1
  end

  monitor(ARGV.fetch(0), domain: ARGV.fetch(1, 'login.gov'))
end

if $0 == __FILE__
  main
end
