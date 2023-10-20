# frozen_string_literal: true

my_gem_path = Dir['./vendor/bundle/ruby/3.2.0/gems/**/lib']
$LOAD_PATH.unshift(*my_gem_path)

require 'benchmark'
require 'logger'
require 'aws-sdk-sqs'


module IdentityKMSMonitor

  # Class for scheduling CloudTrail events to be rechecked
  class CloudTrailRequeue < Functions::AbstractLambdaHandler

    Functions.register_handler(self, 'cloudtrail-requeue')

    def initialize(log_level: Logger::INFO, dry_run: true, sqs: nil)
      super(log_level: log_level, dry_run: dry_run)

      begin
        @sqs = sqs || Aws::SQS::Client.new
        @cloudtrail_requeue_url = ENV.fetch('CT_REQUEUE_URL')
        @cloudtrail_queue_url = ENV.fetch('CT_QUEUE_URL')
      end
    end

    # This is the main CLI handler function
    #
    def cli_main(_args)
      log.info('Reading JSON event from STDIN...')
      event = JSON.parse($stdin.read)
      process_event(event)
    end

    # This is the main lambda handler function
    #
    # @param [Hash, String] event The event received from AWS Lambda
    # @param context The context received from AWS Lambda
    #
    def lambda_main(event:, context:)
      _ = context

      while transfer_messages
      end
    end

    # @param [Hash] record
    def transfer_messages
      receive_resp = @sqs.receive_message(
        {
          queue_url: @cloudtrail_requeue_url,
          message_attribute_names: ['RetryCount'],
          max_number_of_messages: 10,
          visibility_timeout: 120,
          wait_time_seconds: 20,
        }
      )

      if receive_resp.messages.empty?
        log.info 'No messages found.'
        return false
      end


      log.debug "Pulled from the requeue: #{receive_resp.messages}"
      messages_to_send = build_batch_send_message(receive_resp.messages)

      log.debug "Sending Messages to the primary queue: #{messages_to_send}"
      send_resp = @sqs.send_message_batch(
        {
          queue_url: @cloudtrail_queue_url,
          entries: messages_to_send,
        }
      )

      log_failed_to_send(send_resp.failed)

      log.debug "Successfuly sent to primary queue: #{send_resp.successful}"
      messages_to_delete = build_batch_delete_message(send_resp.successful, receive_resp.messages)

      log.debug "Deleteing from the requeue: #{messages_to_delete}"
      delete_resp = @sqs.delete_message_batch(
        {
          queue_url: @cloudtrail_requeue_url,
          entries: messages_to_delete,
        }
      )

      if self.log.level > Logger::DEBUG
        log.info "Pulled #{receive_resp.messages.length} messages." +
                 "Sent #{send_resp.successful.length} messages."    +
                 "Removed #{delete_resp.successful.length} messages."
      end

      return true
    rescue Aws::SQS::Errors::ServiceError => e
      log.error "Failure publishing to SQS: #{e.inspect}"
      raise
    end

    def build_batch_send_message(messages)
      batch_message = []
      messages.map do |message|
        batch_message.append(
          {
            id: message.message_id,
            message_body: message.body,
            # 15 Minutes. Guarantees the cloudtrail-processor doesn't immediately re-process while this is running
            delay_seconds: 900,
            message_attributes: {
              'RetryCount' => {
                string_value: message.message_attributes['RetryCount'].string_value,
                data_type: 'Number',
              },
            },
          }
        )
      end

      return batch_message
    end

    def build_batch_delete_message(successful_messages, received_messages)
      batch_delete = []
      successful_messages.map do |sent|
        index = received_messages.index { |received| received.message_id == sent.id }
        batch_delete.append(
          {
            id: sent.message_id,
            receipt_handle: received_messages[index].receipt_handle,
          }
        )
      end
      return batch_delete
    end

    def log_failed_to_send(messages)
      messages.map do |message|
        log.error "Failed to send #{message.message_id}. Status Code #{message.code}. #{message.message}"
      end
    end
  end
end
