#!/usr/bin/env ruby

require 'rest-client'

def hit_db_healthcheck(env, domain: 'login.gov')
  url = "https://idp.#{env}.#{domain}/api/health/database"

  begin
    RestClient.get(url)
  rescue RestClient::ExceptionWithResponse => err
    err.response
  end
end

def monitor(env, interval: 2, domain: 'login.gov')
  results = []
  loop do
    row = [Time.now, hit_db_healthcheck(env, domain: domain)]
    results << row

    puts "#{row.first}: #{row.last.code} #{row.last.net_http_res.msg}"
    sleep interval
  end
rescue Interrupt
  return results
end
