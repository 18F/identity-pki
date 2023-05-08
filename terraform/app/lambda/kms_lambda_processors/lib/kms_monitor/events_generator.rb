# frozen_string_literal: true

my_gem_path = Dir['./vendor/bundle/ruby/2.7.0/gems/**/lib']
$LOAD_PATH.unshift(*my_gem_path)

require 'json'
require 'aws-sdk-cloudwatch'
require 'aws-sdk-cloudwatchevents'

module IdentityKMSMonitor

  # Class for receiving KMS correlation events from the CloudTrail lambda and
  # creating CloudWatch events for easy monitoring.
  class CloudWatchEventGenerator < Functions::AbstractLambdaHandler

    attr_reader :dynamo

    Functions.register_handler(self, 'events-generator')

    def initialize(log_level: Logger::INFO, dry_run: true, cloudwatch: nil,
                   cloudwatch_events: nil)
      super(log_level: log_level, dry_run: dry_run)

      begin
        @cloudwatch = cloudwatch || Aws::CloudWatch::Client.new
        @cloudwatch_events = cloudwatch_events ||
                             Aws::CloudWatchEvents::Client.new
      rescue StandardError
        log.error('Failed to create AWS clients. Do you have AWS creds?')
        raise
      end
    end

    # This is the main CLI handler function
    #
    def cli_main(_args)
      log.info('Reading JSON event from STDIN...')
      event = JSON.parse(STDIN.read)
      process_event(event)
    end

    # This is the main lambda handler function
    #
    # @param [Hash, String] event The event received from AWS Lambda
    # @param context The context received from AWS Lambda
    #
    def lambda_main(event:, context:)
      _ = context
      process_event(event)
    end

    # @param [Hash] event
    def process_event(event)
      log.info("Event received: #{event}")
      process_records(event.fetch('Records'))
    end

    # @param [Array<Hash>] records
    def process_records(records)
      records.each do |record|
        process_record(record)
      end
    end

    # @param [Hash] record
    def process_record(record)
      body = JSON.parse(record.fetch('body'))
      # I heard you like JSON, so I put JSON in your JSON.
      message = JSON.parse(body.fetch('Message'))

      put_metric(message)

      unless message.fetch('correlated')
        put_event(message)
      end
    end

    def put_metric(message)
      context = message.fetch('context')
      metric_name = if message.fetch('correlated')
                      "#{context}-matched"
                    else
                      "#{context}-unmatched"
                    end

      log.info "Writing metric data for #{metric_name}"
      @cloudwatch.put_metric_data(
        namespace: "#{ENV.fetch('ENV_NAME')}/kmslog",
        metric_data: [
          {
            metric_name: metric_name.to_s,
            value: 1,
            unit: 'Count',
            timestamp: message.fetch('timestamp').to_s,
          },
        ]
  )
    end

    def put_event(message)
      event_detail = {
        'environment' => ENV.fetch('ENV_NAME'),
        'matched' => false,
        'uuid' => message.fetch('uuid').to_s,
        'context' => message.fetch('context').to_s,
        'timestamp' => message.fetch('timestamp').to_s,
        'cloudtrail_id' => message.fetch('cloudtrail_id').to_s,
      }.to_json

      log.info 'Writing a CloudWatch event for an uncorrelated KMS event.'
      @cloudwatch_events.put_events(
        entries: [
          {
            time: message.fetch('timestamp').to_s,
            source: 'gov.login.app',
            detail_type: 'KMS Log Unmatched',
            detail: event_detail,
          },
        ]
                                    )
    end
  end
end
