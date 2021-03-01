require 'rails_helper'

RSpec.describe ApplicationController do
  let(:trace_id) { 'some-trace-id-abcdef' }

  before do
    request.headers['X-Amzn-Trace-Id'] = trace_id
  end

  describe '#append_info_to_payload' do
    let(:payload) { {} }

    it 'adds user_uuid, user_agent and ip, trace_id to the lograge output' do
      controller.append_info_to_payload(payload)

      expect(payload).to eq(
        user_agent: request.user_agent,
        ip: request.remote_ip,
        host: request.host,
        trace_id: trace_id
      )
    end
  end
end
