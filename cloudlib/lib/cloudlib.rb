# frozen_string_literal: true

require 'logger'

require 'aws-sdk'
require 'subprocess'

# Top-level module for all cloudlib functionality
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

  def self.class_log(_klass, stream)
    log = Logger.new(stream)
    # log.progname = klass.name
    log.progname = name
    log.level = log_level
    log
  end

  def self.log_level
    return @log_level if @log_level

    if ENV['CL_LOG_LEVEL'] && !ENV['CL_LOG_LEVEL'].empty?
      @log_level = Integer(ENV['CL_LOG_LEVEL'])
      return @log_level
    end

    @log_level = Logger::INFO
  end

  def self.log_level=(val)
    @log_level = val
  end
end

require_relative './cloudlib/version'
require_relative './cloudlib/errors'
require_relative './cloudlib/autoscaling'
require_relative './cloudlib/ec2'
require_relative './cloudlib/list_servers'
require_relative './cloudlib/loadbalancing'
require_relative './cloudlib/ssh'
