# frozen_string_literal: true

RSpec.describe 'main.rb' do
  describe 'lambda handlers' do
    it 'have all the expected entrypoints' do

      # Add new entrypoints here as they are added. This list should match all
      # of the lambda handlers known to terraform.
      handler_methods = [
        'IdentityAudit::GithubAuditor.process',
        'IdentityAudit::AwsIamAuditor.process',
        'IdentityKMSMonitor::CloudTrailToDynamoHandler.process',
      ]

      handler_methods.each do |handler|
        klass_s, method_s = handler.split('.', 2)

        klass = Module.const_get(klass_s)

        expect(klass).to be_a(Class)
        expect(klass.ancestors).to include(Functions::AbstractLambdaHandler)

        expect(klass).to respond_to(method_s)

        method = klass.method(method_s)

        # assert that the method accepts event and context keywords
        expect(method.parameters).to include([:keyreq, :event])
        expect(method.parameters).to include([:keyreq, :context])
      end
    end
  end
end
