#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../cloudlib.rb'
require 'optparse'
require 'shellwords'

# Helps run a command/document on IDP boxes
class IDPCommand
  Config = Struct.new(
    :pick_strategy,
    :host,
    :subcommand,
    :reason,
    :investigator,
    keyword_init: true
  )

  def self.parse!(argv: ARGV, stdout: STDOUT, stdin: STDIN, stderr: STDERR)
    basename = File.basename($PROGRAM_NAME)

    config = Config.new(
      pick_strategy: nil,
      host: nil,
      subcommand: [],
      reason: nil,
      investigator: nil,
    )

    parser = OptionParser.new do |opts|
      opts.banner = <<~EOS
        usage: #{basename} [OPTIONS] [COMMAND] [COMMANDARGS...]

        Performs a document script from deployed boxes, and
        prompts for investigator, reason on STDIN if not provided

        Examples:

            # Look up user UUID
            #{basename} --any asg-prod-idp uuid-lookup user1@example.com user2@example.com

        Options:
      EOS

      opts.on('-i=INVESTIGATOR', '--investigator=INVESTIGATOR', 'Name of investigator') do |investigator|
        config.investigator = investigator
      end

      opts.on('-r=REASON', '--reason=REASON', 'Reason for running script') do |reason|
        config.reason = reason
      end

      opts.on('-h=HOST', '--host=HOST', 'SSM to specific host') do |name|
        config.pick_strategy = :unique
        config.host = name
      end

      opts.on('-1=NAME', '--any=NAME', 'SSM to random server matching name') do |name|
        config.pick_strategy = :random
        config.host = name
      end

      opts.on('--newest=NAME', 'Pick server with most recent boot time') do |name|
        config.pick_strategy = :newest
        config.host = name
      end

      opts.on('--oldest=NAME', 'Pick server with oldest boot time') do |name|
        config.pick_strategy = :oldest
        config.host = name
      end

      opts.on('-P=NAME', '--prompt=NAME', 'Pick server interactively if ambiguous') do |name|
        config.pick_strategy = :prompt
        config.host = name
      end

      opts.on('--help') do
        puts opts
        exit 0
      end
    end

    ordered_args = []
    unrecognized_flags = []

    begin
      parser.order!(argv) do |non_option|
        ordered_args << non_option
      end
    rescue OptionParser::InvalidOption => e
      unrecognized_flags += e.args
      retry
    end

    config.subcommand = [*ordered_args, *unrecognized_flags]

    if config.host.to_s.empty?
      stderr.puts "ERROR: Missing server group (use one of --host, --any, --newest, --oldest)"
      exit 1
    end

    if config.subcommand.empty?
      stderr.puts "ERROR: Missing subcommand and arguments"
      exit 1
    end

    if !config.investigator
      stdout.print "Enter name of investigator: "
      config.investigator = stdin.gets.chomp
    end

    if !config.reason
      stdout.print "Enter reason: "
      config.reason = stdin.gets.chomp
    end

    new(config: config)
  end

  attr_reader :config

  def initialize(config:)
    @config = config
  end

  # @return [Aws::SSM::Types::GetCommandInvocationResult]
  def run(command:)
    instance = Cloudlib::EC2.new.get_instance_by_name_or_id(
      config.host,
      pick_strategy: config.pick_strategy
    )

    awsusername = Aws::STS::Client.new.get_caller_identity.user_id.split(':').last

    Cloudlib::SSM::Single.new(
      instance: instance,
      document: command,
      parameters: {
        reason: [Shellwords.shellescape(config.reason)],
        investigator: [Shellwords.shellescape(config.investigator)],
        subcommand: [Shellwords.shelljoin(config.subcommand)],
        awsusername: [Shellwords.shellescape(awsusername)],
      },
    ).ssm_send_command(show_progress_bar: true, raise_on_failure: false)
  end

  def output!(stdout: STDOUT, stderr: STDERR, command:)
    response = run(command: command)

    if response.status == 'Success'
      stdout.puts response.standard_output_content
      exit 1
    end
  end
end