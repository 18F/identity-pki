#!/usr/bin/env ruby
# coding: utf-8

require 'uri'
require 'rest-client'
require 'pry'

#RemoveStickiness = false
RemoveStickiness = true

RestClient.log = STDOUT

def main
  puts ''

  site = 'https://secure.login.gov'

  r_get = RestClient.get(site + '/users/password/new')

  match = /name="csrf-token" content="([^"]+)"/.match(r_get.body)
  raise 'could not find csrf-token' unless match

  csrf_token = match.captures.fetch(0)

  cookie_jar = r_get.cookie_jar

  payload = URI.encode_www_form(
    'authenticity_token' => csrf_token,
    'password_reset_email_form[email]' => 'test@test.com',
    'commit' => 'Continue',
    'utf8' => '✓'
  )

  if RemoveStickiness
    puts 'REMOVING STICKINESS'
    new_jar = HTTP::CookieJar.new
    cookie_jar.reject {|c| c.name == 'AWSALB' }.each {|c| new_jar.add(c) }
  else
    puts 'not removing stickiness'
    new_jar = cookie_jar.dup
  end

  #binding.pry

  begin
    r_post = RestClient::Request.execute(method: :post, payload: payload, url: site + '/users/password', cookies: new_jar)
  rescue RestClient::Found => err
    puts 'Got HTTP 302'
    r_post = err.response

    first_redirected_to = err.response.headers.fetch(:location)
    puts 'Following redirection to ' + first_redirected_to

    begin
      second_r = r_post.follow_get_redirection
    rescue RestClient::Found => err
      redirected_to = err.response.headers.fetch(:location)
      puts "got 302 Found, redirecting to #{redirected_to}"

      puts 'following redirection'
      final_r = err.response.follow_redirection

      puts final_r.inspect
    rescue RestClient::ExceptionWithResponse => err
      puts 'Unexpected error'
      puts err.inspect
      binding.pry
    else
      puts 'got no error'
      if second_r.body.include?('We sent an email to')
        puts 'OK SUCCESS'
        return 0
      end

      if second_r.body.include?('Oops, something went wrong')
        print "\033[1;31m" if STDOUT.tty?
        puts 'FAILED: got Oops, something went wrong'
        print "\033[m" if STDOUT.tty?
        return 1
      end

      puts 'NO MESSAGE FOUND'
      binding.pry
    end
  end

  #binding.pry
end

exit main
