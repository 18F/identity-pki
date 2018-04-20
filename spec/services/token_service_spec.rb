require 'rails_helper'

RSpec.describe TokenService do
  let(:token_service) { described_class.instance }

  let(:data) { { 'a' => 'b' } }

  it 'opens a boxed value' do
    expect(token_service.open(token_service.box(data))).to eq data
  end
end
