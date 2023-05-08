# frozen_string_literal: true

module Functions

  # Parent class for lambda handlers. New handlers should inherit from this
  # class.
  #
  # Lambda operation:
  # Handlers must override the {#lambda_main} method. The
  # recommended default lambda handler entrypoint is the class method
  # `.process()` provided by this class, which instantiates the class using
  # config from environment variables and then calls `#lambda_main`.
  #
  # CLI operation:
  # Subclasses should invoke {Functions.register_handler} and define a method
  # {#cli_main} to make themselves available to run from the CLI. The CLI
  # portion is not strictly necessary, but is useful for local development and
  # testing.
  #
  class AbstractLambdaHandler

    # Initializer for Lambda handlers. Override this method in subclasses with
    # any specialized functionality, but don't forget to call super!
    #
    # @param [Integer] log_level Default log level for `#log`
    # @param [Boolean] dry_run Whether to enable dry run mode
    #
    def initialize(log_level: Logger::INFO, dry_run: true)
      @dry_run = dry_run
      log.level = log_level
      log.info("super#initialize, dry_run: #{dry_run.inspect}")
    end

    # @return [Boolean] Whether we are currently running in dry run mode.
    def dry_run?
      !!@dry_run
    end

    # Logger for handlers (class method)
    # @return [Logger]
    def self.log
      @log ||= Logger.new(STDERR).tap { |l|
        l.progname = name
      }
    end

    # Logger for handlers
    # @return [Logger]
    def log
      @log ||= self.class.log
    end

    # Main entrypoint for running the handler with an AWS Lambda event.
    # Subclasses must implement this method.
    #
    # @param [Hash,String] event The event received from AWS Lambda
    # @param context The context received from AWS Lambda
    #
    # @return [Object]
    #
    def lambda_main(event:, context:)
      _ = event, context # discard args
      raise NotImplementedError.new('Subclasses must implement lambda_main')
    end

    # Main entrypoint for running the handler from the CLI. Subclasses should
    # implement this method if they want to be run on the command line.
    #
    # @param [Array] args The ARGV argument array as received from the command
    #   line.
    def cli_main(args)
      _ = args
      raise NotImplementedError.new('Subclasses should implement cli_main')
    end

    # Instantiate the handler and call {#lambda_main}. This is the top level
    # entrypoint called by `main.rb`. Subclasses are NOT expected to override
    # this method unless they want to memoize or otherwise change behavior for
    # handler object instantiation (e.g. to reuse the same handler instance
    # across many events).
    #
    # @param [Hash,String] event The event received from AWS Lambda
    # @param context The context received from AWS Lambda
    #
    # @return [Object]
    #
    # @see .new_with_env_config
    # @see #lambda_main
    #
    def self.process(event:, context:)
      log.info('Instantiating handler to process lambda event')
      log.info("Current git revision: #{deployed_git_revision}")
      # Lambda defaults to real run mode
      new_with_env_config(dry_run_default: false)
        .lambda_main(event: event, context: context)
    end

    # Instantiate the handler and call {#cli_main}.
    #
    # @param [Array] args The ARGV argument array as received from the command
    #   line.
    #
    # @see .new_with_env_config
    # @see #cli_main
    #
    def self.cli_process(args)
      # CLI defaults to dry run mode
      new_with_env_config(dry_run_default: true)
        .cli_main(args)
    end

    # Instantiate the handler with defaults from environment variables.
    #
    # If `DEBUG` is set and nonempty, default to `DEBUG` logging and dry run
    # mode. Otherwise default to `INFO` logging and real run mode.
    #
    # Override the log level with `LOG_LEVEL`, if set.
    #
    # @see #initialize
    #
    # @param kwargs Passed through to .new
    #
    # @return [AbstractLambdaHandler]
    #
    def self.new_with_env_config(dry_run_default: true, **kwargs)
      # Enable debug mode if $DEBUG is set and nonempty
      if ENV['DEBUG'] && !ENV['DEBUG'].empty?
        dry_run = true
        log_level = Logger::DEBUG
      else
        dry_run = dry_run_default
        log_level = Logger::INFO
      end

      # Disable dry run and run in real mode if REAL_RUN is set
      if ENV['REAL_RUN'] && !ENV['REAL_RUN'].empty?
        dry_run = false
      end

      # override log level from $LOG_LEVEL if provided
      if ENV['LOG_LEVEL'] && !ENV['LOG_LEVEL'].empty?
        log_level = Integer(ENV.fetch('LOG_LEVEL'))
      end

      log.debug('Initializing with config from env')

      new(log_level: log_level, dry_run: dry_run, **kwargs)
    end

    def self.deployed_git_revision
      File.read(File.join(File.dirname(__FILE__), '../../REVISION.txt')).chomp
    end
  end

end

