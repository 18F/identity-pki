#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative './lib/functions'

# To add a new handler function, create a subclass of
# {Functions::AbstractLambdaHandler}.
#
# == Handling Lambda events:
#
# In the subclass, override `#lambda_main` to define what should happen when
# the lambda receives an event. The top level entrypoint for the lambda will be
# a class method provided by the parent class: {AbstractLambdaHandler.process}.
# You will not normally need to override this `.process` class method, which is
# the handler method that should be referenced in AWS Lambda configuration when
# creating the Lambda itself:
#
#   resource "aws_lambda_function" "my-lambda" {
#     handler = "main.MyModule::MyClass.process"
#     ...
#
# == Handling CLI events:
#
# If you want to be able to call a lambda handler subclass from this CLI for
# development or testing, call {Functions.register_handler} to associate the
# handler with a CLI name.
#
# In the subclass, override `#cli_main` to define what should happen when the
# handler is run on the CLI. The corresponding class method provided by the
# parent class is {AbstractLambdaHandler.process_cli}, which you will not
# normally need to override.
#
# The CLI methods are useful for testing, but not necessary.
#


# Require handler modules here so they can be loaded by CLI or by AWS Lambda.
require_relative './lib/audit'
require_relative './lib/kms_monitor'

# ^ Load new function libraries here


# Main CLI entrypoint
#
def usage
  STDERR.puts "usage: #{$0} LAMBDA [ARGS...]\n\n"
  STDERR.puts 'known lambdas:'

  maxlen = Functions.registered_classes.keys.map(&:length).max
  Functions.registered_classes.sort.each do |name, klass|
    puts '  - ' + name.ljust(maxlen) + "\t\t(#{klass.name})"
  end
  STDERR.puts
  STDERR.puts <<-EOM
Set REAL_RUN=1 to enable real run mode (dry run is default for CLI)
Set DEBUG=1 to enable dry run and debug output
Set LOG_LEVEL=N to set log level to any integer N
  EOM
end

def cli_main
  if ARGV.empty?
    usage
    exit 1
  end

  if %w[-h --help].include?(ARGV.first)
    usage
    exit
  end

  command_name = ARGV.shift

  klass = Functions.get_class(command_name)
  klass.cli_process(ARGV)
end

if $0 == __FILE__
  cli_main
end
