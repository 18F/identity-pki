# frozen_string_literal: true

# Top level lambda function wrapper module
#
# Define a new Lambda function handler by subclassing
# {Functions::AbstractLambdaHandler}. Require the class from main.rb, and use
# the `.process` class method on the subprocess as the Lambda entrypoint. If
# you want the function to be accessible via the CLI for testing, then call
# {Functions.register_handler} with the class.
#
module Functions

  # @return [Hash{String => Class}] A mapping from string CLI labels to
  #   {AbstractLambdaHandler} subclasses.
  def self.registered_classes
    @registered_classes ||= {}
  end

  # Get a registered class
  #
  # @param [String] cli_name
  # @return [Class]
  def self.get_class(cli_name)
    registered_classes.fetch(cli_name)
  end

  # Add a Lambda handler class to the set of known classes with friendly CLI
  # labels. These labels are used to invoke the handlers on the command line
  # for local development or testing.
  #
  # @param [AbstractLambdaHandler] klass The lambda handler to register
  # @param [String] cli_name A friendly CLI label
  # @param [Boolean] override Whether to allow replacing existing methods
  #
  def self.register_handler(klass, cli_name, override: false)
    unless klass.is_a?(Class)
      raise ArgumentError.new(
        "klass must be a Class, got: #{klass.inspect}"
      )
    end

    unless klass <= AbstractLambdaHandler
      warn([
        'Functions.register_handler:',
        'expected klass to be subclass of AbstractLambdaHandler, got',
        klass.ancestors.inspect,
      ].join(' '))
    end


    unless cli_name.is_a?(String)
      raise ArgumentError.new(
        "cli_name must be a String, got #{cli_name.inspect}"
      )
    end

    if registered_classes.include?(cli_name) && !override
      raise KeyError.new('Duplicate handler name: ' + cli_name.inspect)
    end

    registered_classes[cli_name] = klass
  end
end

require_relative 'functions/abstract_lambda_handler'
