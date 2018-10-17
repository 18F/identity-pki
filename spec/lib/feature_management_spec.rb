require 'rails_helper'

RSpec.describe FeatureManagement do
  let(:subject) { described_class }

  describe '#nonce_bloom_filter_enabled?' do
    it 'is true when enabled' do
      allow(Figaro.env).to receive(:nonce_bloom_filter_enabled).and_return('true')
      expect(subject.nonce_bloom_filter_enabled?).to eq true
    end

    it 'is false when not enabled' do
      allow(Figaro.env).to receive(:nonce_bloom_filter_enabled).and_return('false')
      expect(subject.nonce_bloom_filter_enabled?).to eq false
    end
  end
end
