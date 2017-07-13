#!/usr/bin/env ruby
require 'json'
require 'tmpdir'

if ARGV.length == 3
  data_bag = ARGV[0]
  env = ARGV[1]
  bucket = ARGV[2]

  config = JSON.parse(File.read(data_bag))
  # id = config.delete('id')
  # build_env_config = config[env].delete('build_env')
  tmpdir = Dir.mktmpdir

  config[env].each do |k,v|
    File.open("#{tmpdir}/#{k}",'w') {|f| f.write(v) }
  end

  exec("aws s3 sync #{tmpdir} s3://#{bucket}/#{env}/")
  FileUtils.rm_rf(tmpdir)
else
  puts "Usage: databag_to_citadel.rb <unencrypted_data_bag> <env> <bucket>"
end
