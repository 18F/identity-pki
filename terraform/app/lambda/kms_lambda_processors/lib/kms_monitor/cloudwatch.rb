# frozen_string_literal: true

my_gem_path = Dir['./vendor/bundle/ruby/2.7.0/gems/**/lib']
$LOAD_PATH.unshift(*my_gem_path)

require 'benchmark'
require 'logger'
require 'aws-sdk-dynamodb'

## This is a tigger for null archive

module IdentityKMSMonitor

  # Class for inputting CloudWatch events into DynamoDB
  class CloudWatchKMSHandler < Functions::AbstractLambdaHandler

    attr_reader :dynamo

    Functions.register_handler(self, 'cloudwatch-kms')

    def initialize(log_level: Logger::INFO, dry_run: true, dynamo: nil)
      super(log_level: log_level, dry_run: dry_run)

      begin
        @dynamo = dynamo || Aws::DynamoDB::Client.new
        @retention_seconds = Integer(
          ENV.fetch('RETENTION_DAYS')) * (60 * 60 * 24)
      rescue StandardError
        log.error('Failed to create DynamoDB client. Do you have AWS creds?')
        raise
      end
    end

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
      log.info("process_event: #{event.inspect}")
      process_records(event.fetch('Records'))
    end

    def insert_into_db(uuid, timestamp, data)
      table_name = ENV.fetch('DDB_TABLE')
      ttl = Time.now.utc + @retention_seconds
      ttlstring = ttl.strftime('%s')
      ttlnumber = ttlstring.to_i
      item = {
        'UUID' => uuid,
        'Timestamp' => timestamp,
        'Correlated' => '0',
        'CWData' => data,
        'TimeToExist' => ttlnumber,
      }

      params = {
        table_name: table_name,
        item: item,
      }

      begin
        duration = Benchmark.realtime { dynamo.put_item(params) }
        log.info "Wrote event for UUID #{uuid} in #{duration.round(6)} seconds"

      rescue Aws::DynamoDB::Errors::ServiceError => error
        log.error "Failure adding event: #{error.message}"
        raise
      end
    end

    def decompress(compressed_data)
      data = Base64.decode64(compressed_data)
      uncompressed_data = Zlib::GzipReader.new(
        StringIO.new(data), external_encoding: data.encoding).read
      uncompressed_data
    end

    def get_db_record(uuid, timestamp)
      begin
        result = nil
        duration = Benchmark.realtime do
          result = dynamo.get_item(
            table_name: ENV.fetch('DDB_TABLE'),
            key: {
              'UUID' => uuid,
              'Timestamp' => timestamp,
            },
            consistent_read: true
                                   )
        end
        log.info "get_item took #{duration.round(6)} seconds"
      rescue Aws::DynamoDB::Errors::ServiceError => error
        log.error "Failure retrieving record from table: #{error.message}"
        raise
      end

      result.item
    end

    def update_db_record(dbrecord, kmsevent)
      # If we don't have any CTData, then we are reprocessing an unmatched
      # existing record. If the record is correlated, no update is required.
      if dbrecord['CTData'].nil? || dbrecord['Correlated'] == '1'
        return
      end

      table_name = ENV.fetch('DDB_TABLE')
      ttl = Time.now.utc + @retention_seconds
      ttlstring = ttl.strftime('%s')
      uuid = kmsevent.get_key
      item = {
        'UUID' => uuid,
        'Timestamp' => kmsevent.timestamp,
        'Correlated' => '1',
        'CTData' => dbrecord.fetch('CTData'),
        'CWData' => kmsevent.to_json,
        'TimeToExist' => ttlstring,
      }

      params = {
        table_name: table_name,
        item: item,
      }

      begin
        duration = Benchmark.realtime { dynamo.put_item(params) }
        log.info "Updated record in #{duration.round(6)} seconds"

      rescue Aws::DynamoDB::Errors::ServiceError => error
        log.error "Failure adding event: #{error.message}"
        raise
      end
    end

    def process_records(records)
      records&.each do |record|
        process_record(record)
      end
    end

    def process_record(record)
      data = {}
      record.each do |key, value|
        if key == 'kinesis'
          data = value.fetch('data')
        end
      end

      data = decompress(data)

      logdata = JSON.parse(data)
      log.info("parsed log data: #{logdata.inspect}")

      return if logdata.fetch('messageType') == 'CONTROL_MESSAGE'

      logdata.fetch('logEvents').each do |log_event|
        process_log_event(log_event)
      end
    end

    def process_log_event(log_event)
      extracted_fields = log_event.fetch('extractedFields')

      kmsevent = CloudWatchKMSEvent.new

      timestamp = Time.parse(extracted_fields.fetch('datetime'))
      kmsevent.timestamp = timestamp.strftime('%Y-%m-%dT%H:%M:%SZ')

      # cleanup extra character at beginning of Json string
      jsondata = extracted_fields.fetch('json')
      jsondata = jsondata[1..-1]

      jsondata = JSON.parse(jsondata)

      encryption_context = jsondata.fetch('kms').fetch('encryption_context')
      kmsevent.context = encryption_context.fetch('context')
      kmsevent.uuid = encryption_context.fetch('user_uuid')
      kmsevent.action = jsondata.fetch('kms').fetch('action')

      dbrecord = get_db_record(kmsevent.get_key, kmsevent.timestamp)

      if dbrecord
        update_db_record(dbrecord, kmsevent)
      else
        insert_into_db(kmsevent.get_key, kmsevent.timestamp, kmsevent.to_h)
      end
    end
  end

  # This class represents KMS events we retrieve from CloudWatch.
  class CloudWatchKMSEvent
    attr_accessor :action, :context, :uuid, :timestamp

    def get_key()
      @uuid + '-' + @context
    end

    def to_h(_options = {})
      {
        action: @action,
        uuid: @uuid,
        timestamp: @timestamp,
        context: @context,
      }
    end

    def to_json(*options)
      to_h(*options).to_json(*options)
    end
  end
end
