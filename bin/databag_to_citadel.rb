#!/usr/bin/env ruby
require 'json'
require 'tmpdir'

require 'bundler/setup'

require 'subprocess'

BucketMap = {
  default: 'login-gov-secrets-test',
  'prod' => 'login-gov-secrets',
  'staging' => 'login-gov-secrets',
  'int' => 'login-gov-secrets',
}

def main(data_bag, env, bucket=nil, kms_key_id=nil, delete=false)

  if bucket.nil?
    begin
      bucket = BucketMap.fetch(env)
    rescue KeyError
      bucket = BucketMap.fetch(:default)
      puts "using default bucket: #{bucket}"
    end
  end

  puts "Reading #{data_bag}"

  config = JSON.parse(File.read(data_bag))
  # id = config.delete('id')
  # build_env_config = config[env].delete('build_env')
  tmpdir = Dir.mktmpdir('databag-to-citadel-')

  config[env].each do |k,v|
    if v.is_a?(String)
      content = v
    else
      content = JSON.pretty_generate(v)
    end
    File.open("#{tmpdir}/#{k}",'w') {|f| f.write(content) }
  end

  puts "Converted JSON to files in #{tmpdir}"

  path = "s3://#{bucket}/#{env}/"

  # build command string
  cmd = %w{aws s3 sync --sse aws:kms}
  cmd += ['--sse-kms-key-id', kms_key_id] if kms_key_id
  cmd += ['--delete'] if delete
  cmd += [tmpdir, path]

  # dry run
  dryrun = cmd + ['--dryrun']
  puts 'Executing dry run:'
  puts '+ ' + dryrun.join(' ')
  Subprocess.check_call(dryrun)

  puts 'REAL command to run:'

  puts '+ ' + cmd.join(' ')

  puts 'Press enter to continue...'
  STDIN.gets

  Subprocess.check_call(cmd)

  FileUtils.rm_rf(tmpdir)
end

def usage
  STDERR.puts <<-EOM
Usage: #{File.basename($0)} <unencrypted_data_bag> <env> [<bucket> [<kms_key_id>]]

Convert local config data bag from JSON file into separate S3 files and upload
to the appropriate secrets bucket, encrypting with KMS.

For example:

    #{File.basename($0)} kitchen/data_bags/config/qa.json qa

WARNING: Before running this command, ensure that you have the latest config
data bag downloaded from the chef server.

    #{File.dirname($0)}/chef-databag download ENV config

  EOM
end

if $0 == __FILE__
  if ARGV.length < 2
    usage
    exit 1
  end
  main(*ARGV)
end
