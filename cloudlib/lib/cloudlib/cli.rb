# frozen_string_literal: true

require 'thor'

require_relative 'commands/base'
require_relative 'commands/lambda'

module Cloudlib

  # Cloudlib::CLI is the top-level CLI entrypoint for cloudlib commands.
  class CLI < Cloudlib::Commands::Base

    class_option 'quiet', type: :boolean, desc: 'Decrease log output',
                          aliases: '-q'
    class_option 'verbose', type: :boolean, desc: 'Enable verbose output',
                            aliases: '-v'
    class_option 'log-level', type: :numeric, desc: 'Cloudlib integer log level'

    def initialize(*args)
      super
    ensure
      self.options ||= {}
      Cloudlib.log_level -= 1 if options['verbose']
      Cloudlib.log_level += 1 if options['quiet']
      Cloudlib.log_level = options['log-level'] if options['log-level']
    end


    desc 'lambda COMMAND [ARGS...]', 'Manage/deploy AWS lambdas'
    subcommand 'lambda', Cloudlib::Commands::Lambda

    def self.with_friendly_errors
      yield
    rescue Cloudlib::CLIError => err
      if err.message && err.message != err.class.name
        STDERR.puts "Error: #{err.message}"
        exit 2
      end
      STDERR.puts "Error: #{err.inspect}"
      exit 2
    end
  end
end
