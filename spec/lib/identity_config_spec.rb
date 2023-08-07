require 'rails_helper'

RSpec.describe IdentityConfig do

  describe '#add' do
    it 'raises on invalid ENV value' do
      ic = IdentityConfig.new({aws_region: ['env', 'ABC123456789']})
      expect do
        ic.add(:aws_region, type: :string)
      end.to raise_error(KeyError)
    end
  end

  describe '.key_types' do
    it 'has all _enabled keys as booleans' do
      aggregate_failures do
        IdentityConfig.key_types.select { |key, _type| key.to_s.end_with?('_enabled') }.
          each do |key, type|
            expect(type).to eq(:boolean), "expected #{key} to be a boolean"
          end
      end
    end

    it 'has all _at keys as timestamps' do
      aggregate_failures do
        IdentityConfig.key_types.select { |key, _type| key.to_s.end_with?('_at') }.
          each do |key, type|
            expect(type).to eq(:timestamp), "expected #{key} to be a timestamp"
          end
      end
    end

    it 'has all _timeout keys as numbers' do
      aggregate_failures do
        IdentityConfig.key_types.select { |key, _type| key.to_s.end_with?('_timeout') }.
          each do |key, type|
            expect(type).to eq(:float).or(eq(:integer)), "expected #{key} to be a number"
          end
      end
    end
  end
end
