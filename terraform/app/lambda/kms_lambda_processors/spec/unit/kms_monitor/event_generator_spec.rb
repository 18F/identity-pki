test_event = {"Records"=>[{"messageId"=>"9b990df7-qqqqq", "receiptHandle"=>"QQQQ==", "body"=>"{\n \"Type\" : \"Notification\",\n \"MessageId\" : \"aa0f42fa-qqqqq\",\n \"TopicArn\" : \"arn:aws:sns:district9:19430221:loginenv-kms-logging-events\",\n \"Message\" : \"{\\\"uuid\\\":\\\"bb3b2d0e-qqqq6\\\",\\\"operation\\\":\\\"decrypt\\\",\\\"context\\\":\\\"password-digest\\\",\\\"timestamp\\\":\\\"2019-05-02T18:17:28Z\\\",\\\"cloudtrail_id\\\":\\\"b13247d9-qqqq0\\\",\\\"correlated\\\":false,\\\"late_correlation\\\":false}\",\n \"Timestamp\" : \"2019-05-02T18:46:19.145Z\",\n \"SignatureVersion\" : \"1\",\n \"Signature\" : \"Cof2bVY8Lqqq==\",\n \"SigningCertURL\" : \"https://sns.district9.amazonaws.com/SimpleNotificationService-qqqq9.pem\",\n \"UnsubscribeURL\" : \"https://sns.district9.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:district9:19430221:loginenv-kms-logging-events:0a102881-ffff\"\n}", "attributes"=>{"ApproximateReceiveCount"=>"1", "SentTimestamp"=>"1556822779360", "SenderId"=>"AIDATURTURRO", "ApproximateFirstReceiveTimestamp"=>"1556822784360"}, "messageAttributes"=>{}, "md5OfBody"=>"7b5dd3c149f189e50fdb6d80c5818c49", "eventSource"=>"aws:sqs", "eventSourceARN"=>"arn:aws:sqs:district9:19430221:loginenv-kms-cw-events", "awsRegion"=>"district9"}]}

RSpec.describe IdentityKMSMonitor::CloudWatchEventGenerator do
  describe 'the process method' do
    it 'handles uncorrelated KMS incidents' do
      ENV['ENV_NAME'] = 'login_env'
      fake_cw = Aws::CloudWatch::Client.new(:stub_responses => true)
      fake_cw_events = Aws::CloudWatchEvents::Client.new(
        :stub_responses => true)
      instance = IdentityKMSMonitor::CloudWatchEventGenerator.new(
        cloudwatch: fake_cw, cloudwatch_events: fake_cw_events)
      instance.process_event(test_event)

      # verify that metrics and events were sent correctly
      metrics_sent = fake_cw.api_requests()
      metric_name = metrics_sent[0][:params][:metric_data][0][:metric_name]
      expect(metric_name).to eq 'password-digest-unmatched'

      events_sent = fake_cw_events.api_requests()
      event_type = events_sent[0][:params][:entries][0][:detail_type]
      expect(event_type).to eq 'KMS Log Unmatched'
    end
  end
end
