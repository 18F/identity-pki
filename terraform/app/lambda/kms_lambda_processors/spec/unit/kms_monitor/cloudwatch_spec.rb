control_event = {"Records"=>[{"kinesis"=>{"kinesisSchemaVersion"=>"1.0", "partitionKey"=>"3e21f5e8240cbb048271af4fdb892a1c", "sequenceNumber"=>"49594019693003114422879448339514879444680299351132602370", "data"=>"H4sIAAAAAAAAADWOwQqCQBRFf2WYdYQRariLMBdZQgYtImLSlz7SGZk3FiH+e6PW8nAv956O10AkCjh9GuAB3ySH0zGJb/swTddRyGdcvSXoIalUm7+FycpYFWSDShWRVm1js4lSo0HUE1J7p0xjY1DJLVYGNPHgch174QukGbDjmE91g1bDiNqOLVzXc1zH85cr35v99QaBc8x+euynF7BNCdkTZcFKEJUpmXqw3C6hFMMz26EEQmI0qs15f+2/iTNXgvIAAAA=", "approximateArrivalTimestamp"=>1556050674.253}, "eventSource"=>"aws:kinesis", "eventVersion"=>"1.0", "eventID"=>"shardId-000000000000:49594019693003114422879448339514879444680299351132602370", "eventName"=>"aws:kinesis:record", "invokeIdentityArn"=>"arn:aws:iam::19791211:role/loginenv-lambda-cloudwatch-kms", "awsRegion"=>"jeffs-basement", "eventSourceARN"=>"arn:aws:kinesis:jeffs-basement:19791211:stream/loginenv-kms-app-events"}]}

decrypt_message = {"messageType"=>"DATA_MESSAGE", "owner"=>"19791211", "logGroup"=>"loginenv_/srv/idp/shared/log/kms.log", "logStream"=>"idp-i-05ea7d1d35f8df399.loginenv.identitysandbox.gov", "subscriptionFilters"=>["loginenv-kms-app-log"], "logEvents"=>[
  {"id"=>"34701420244984930149589218301075272436152625254143492097", "timestamp"=>1556065500774, "message"=>"I, [2019-04-24T00:25:00.774192 #5666]  INFO -- : {\"kms\":{\"action\":\"decrypt\",\"encryption_context\":{\"context\":\"password-digest\",\"user_uuid\":\"cafecafe-b4e6-4a4c-8e9d-beef2e191f0b\"}}}", "extractedFields"=>{"datetime"=>"2019-04-24T00:25:00.774192 #5666", "json"=>": {\"kms\":{\"action\":\"decrypt\",\"encryption_context\":{\"context\":\"password-digest\",\"user_uuid\":\"cafecafe-b4e6-4a4c-8e9d-beef2e191f0b\"}}}", "type"=>"I,", "whitespace"=>"--", "info"=>"INFO"}},
  {"id"=>"34701420244984930149589218301075272436152625254143492098", "timestamp"=>1556065500774, "message"=>"I, [2019-04-24T00:25:00.774288 #5667]  INFO -- : {\"kms\":{\"action\":\"decrypt\",\"encryption_context\":{\"context\":\"pii-encryption\",\"user_uuid\":\"cafecafe-b4e6-4a4c-8e9d-beef2e191f0b\"}}}", "extractedFields"=>{"datetime"=>"2019-04-24T00:25:00.774192 #5666", "json"=>": {\"kms\":{\"action\":\"decrypt\",\"encryption_context\":{\"context\":\"pii-encryption\",\"user_uuid\":\"cafecafe-b4e6-4a4c-8e9d-beef2e191f0b\"}}}", "type"=>"I,", "whitespace"=>"--", "info"=>"INFO"}}
  ]}.to_json

def make_encoded_gzip(json)
  gz = Zlib::GzipWriter.new(StringIO.new)
  gz << json
  Base64.encode64(gz.close.string)
end

compressed_decrypt_message = make_encoded_gzip(decrypt_message)

decrypt_event = {"Records"=>[{"kinesis"=>{"kinesisSchemaVersion"=>"1.0", "partitionKey"=>"724fd507781225d0fe45ad5afe3b85fd", "sequenceNumber"=>"49594019693003114422879452068920468967293942684815720450", "data"=>compressed_decrypt_message, "approximateArrivalTimestamp"=>1556065507.32}, "eventSource"=>"aws:kinesis", "eventVersion"=>"1.0", "eventID"=>"shardId-000000000000:49594019693003114422879452068920468967293942684815720450", "eventName"=>"aws:kinesis:record", "invokeIdentityArn"=>"arn:aws:iam::19791211:role/loginenv-lambda-cloudwatch-kms", "awsRegion"=>"jeffs-basement", "eventSourceARN"=>"arn:aws:kinesis:jeffs-basement:19791211:stream/loginenv-kms-app-events"}]}

RSpec.describe IdentityKMSMonitor::CloudWatchKMSHandler do
  describe 'something in the cloudtrail class' do
    it 'can process an empty list of records' do
      ENV['DDB_TABLE'] = 'fake_table'
      instance = IdentityKMSMonitor::CloudWatchKMSHandler.new
      instance.process_event({ 'Records' => [] })
    end
    it 'can process a control message' do
      ENV['DDB_TABLE'] = 'fake_table'
      ENV['RETENTION_DAYS'] = '365'
      instance = IdentityKMSMonitor::CloudWatchKMSHandler.new
      instance.process_event(control_event)
    end
    it 'can process a decrypt event' do
      ENV['DDB_TABLE'] = 'fake_table'
      ENV['RETENTION_DAYS'] = '365'
      fake_dynamo = Aws::DynamoDB::Client.new(stub_responses: true)
      fake_dynamo.stub_responses(:get_item, {item: nil})
      fake_dynamo.stub_responses(:put_item, nil)
      instance = IdentityKMSMonitor::CloudWatchKMSHandler.new(dynamo: fake_dynamo)
      instance.process_event(decrypt_event)

      password_entry = fake_dynamo.api_requests[1][:params][:item]
      expect(password_entry['CWData'][:m]['context'][:s]).to eq 'password-digest'

      pii_entry = fake_dynamo.api_requests[3][:params][:item]
      expect(pii_entry['CWData'][:m]['context'][:s]).to eq 'pii-encryption'
    end
  end
end
