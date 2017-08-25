require 'logger'

require 'aws-sdk'
require 'subprocess'

module Cloudlib
  def self.log
    return @log if @log
    @log = Logger.new(STDERR)
    @log.progname = self.name
    @log.level = log_level
    @log
  end

  def self.cli_log
    return @cli_log if @cli_log
    @cli_log = Logger.new(STDERR)
    @cli_log.progname = File.basename($0)
    @cli_log.level = log_level
    @cli_log
  end

  def self.class_log(klass, stream)
    log = Logger.new(stream)
    log.progname = name
    log.level = log_level
    log
  end

  def self.log_level
    return @log_level if @log_level

    if ENV['CL_LOG_LEVEL']
      @log_level = Integer(ENV['CL_LOG_LEVEL'])
      return @log_level
    end

    @log_level = Logger::DEBUG
  end

  def self.log_level=(val)
    @log_level = val
  end
end

require_relative './cloudlib/version'
require_relative './cloudlib/errors'
require_relative './cloudlib/ec2'
require_relative './cloudlib/ssh'
