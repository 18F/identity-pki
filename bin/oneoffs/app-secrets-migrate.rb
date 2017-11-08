#!/usr/bin/env ruby

require 'bundler/setup'

require 'subprocess'
require 'yaml'

# STEPS
# - SSH to existing oldest IDP server, get existing application.yml and
#   database.yml
# - Merge in database.yml secrets (user,host,pass) into application.yml before
#   uploading
#     database => database_name
#     database_username
#     database_host
#     database_password
# - Upload application.yml to app secrets bucket

def usage
  STDERR.puts <<-EOM
usage: #{$0} ENVIRONMENT

Convert existing application.yml/database.yml secrets to the new app secrets
format and upload them to the app secrets bucket.
  EOM
end

Region = 'us-west-2'

DatabaseAttrs = {
  'database' => 'database_name',
  'username' => 'database_username',
  'host' => 'database_host',
  'password' => 'database_password',
}

def ssh_oldest_idp_cmd(env, cmd)
  ssh_instance = File.join(File.dirname($0), '../ssh-instance')
  full_command = [ssh_instance, '-q', '--oldest', "asg-#{env}-idp"] + cmd
  puts '+ ' + full_command.inspect
  Subprocess.check_output(full_command)
end

def get_existing_secret_files(env)
  puts 'Getting secret files via SSH'
  application_yml = ssh_oldest_idp_cmd(env, %w{sudo cat /srv/idp/shared/config/application.yml})
  database_yml = ssh_oldest_idp_cmd(env, %w{sudo cat /srv/idp/shared/config/database.yml})

  [YAML.safe_load(application_yml), YAML.safe_load(database_yml)]
end

def get_account_id
  Subprocess.check_output(%w{aws sts get-caller-identity --output text --query Account}).chomp
end

def app_secrets_s3_bucket
  "login-gov.app-secrets.#{get_account_id}-#{Region}"
end

def app_secrets_path(env, filename)
  "s3://#{app_secrets_s3_bucket}/#{env}/idp/v1/#{filename}"
end

def upload_app_secrets(content, s3_url)
  cmd = %W{aws s3 cp --sse aws:kms - #{s3_url}}
  puts '+ ' + cmd.inspect
  Subprocess.check_call(cmd, stdin: Subprocess::PIPE) do |p|
    p.communicate(content)
  end
end

def convert_and_upload_yaml_files(env:, application_data:, database_data:)
  puts "Found #{application_data.fetch('production').keys.length} production keys"

  DatabaseAttrs.each do |db_key, app_key|
    application_data['production'][app_key] = database_data.fetch('production').fetch(db_key)
  end

  puts 'Merged in database values'

  generated = "# First converted from Citadel at #{Time.now.to_s}\n" \
    + YAML.dump(application_data)

  puts "Generated secrets file is #{generated.length} bytes"

  s3_url = app_secrets_path(env, 'application.yml')

  upload_app_secrets(generated, s3_url)

  puts "Uploaded to #{s3_url.inspect}"

  puts 'All done!'

  puts 'Run these commands to inspect your handiwork:'
  puts "aws s3 ls #{s3_url}"
  puts "aws s3 cp #{s3_url} -"

  s3_url
end

def main(env)
  puts "Starting up, env #{env.inspect}"
  application_data, database_data = get_existing_secret_files(env)

  puts 'Downloaded application.yml and database.yml'

  convert_and_upload_yaml_files(env: env,
                                application_data: application_data,
                                database_data: database_data)
end

if $0 == __FILE__

  if ARGV.empty?
    usage
    exit 1
  end

  main(ARGV.fetch(0))
end
