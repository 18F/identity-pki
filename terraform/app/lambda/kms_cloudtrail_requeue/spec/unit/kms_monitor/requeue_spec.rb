require 'aws-sdk-sqs'

def construct_random_message
    message = Aws::SQS::Types::Message.new
    message.message_id = "#{SecureRandom.uuid}"
    message.receipt_handle = SecureRandom.base64
    message.body = "This is a random body message: " + SecureRandom.alphanumeric
    message.md5_of_body = Digest::MD5.hexdigest(message.body)
    attributes = Aws::SQS::Types::MessageAttributeValue.new
    attributes.string_value = rand(13).to_s
    attributes.data_type = 'Number'
    message.message_attributes = {
      'RetryCount' => attributes
    }

    return message
end


def receive_resp

  resp = Aws::SQS::Types::ReceiveMessageResult.new

  resp.messages=[]

  for index in 0..9 do 
    resp.messages[index] = construct_random_message
  end

  return resp
end

ENV['AWS_REGION'] = 'castletown'
ENV['DDB_TABLE'] = 'fake_table'
ENV['RETENTION_DAYS'] = '365'
ENV['SNS_EVENT_TOPIC_ARN'] = 'arn:aws:sns:us-south:19820810:mytopic'
ENV['CT_QUEUE_URL'] = 'https://us-north.queue.amazonaws.com/19410519/login-kms-ct-events'
ENV['CT_REQUEUE_URL'] = 'https://us-north.queue.amazonaws.com/19410519/login-kms-cloudtrail-requeue'
ENV['MAX_SKEW_SECONDS'] = '5'

RSpec.describe IdentityKMSMonitor::CloudTrailRequeue do
  describe 'the process method' do
    it 'pulls message from one queue to another' do
      fake_sqs = Aws::SQS::Client.new(stub_responses: true)
      fake_sqs.stub_responses(:receive_message, receive_resp)
      fake_sqs.stub_responses(:send_batch_message)
      fake_sqs.stub_responses(:delete_batch_message, nil)
      instance = IdentityKMSMonitor::CloudTrailRequeue.new(sqs: fake_sqs)
      instance.transfer_messages
    end
    it 'handles empty queues' do
      fake_sqs = Aws::SQS::Client.new(stub_responses: true)
      fake_sqs.stub_responses(:send_batch_message, nil)
      fake_sqs.stub_responses(:delete_batch_message, nil)
      instance = IdentityKMSMonitor::CloudTrailRequeue.new(sqs: fake_sqs)
      instance.transfer_messages

    end
  end
end
