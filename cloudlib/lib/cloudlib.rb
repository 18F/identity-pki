require 'logger'

require 'aws-sdk'
require 'subprocess'

module Cloudlib
  def self.log
    return @log if @log
    @log = Logger.new(STDERR)
    @log.progname = self.name
    @log
  end
end

require_relative './cloudlib/version'
require_relative './cloudlib/errors'
require_relative './cloudlib/ec2'
