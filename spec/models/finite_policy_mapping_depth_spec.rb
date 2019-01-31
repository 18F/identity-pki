require 'rails_helper'

RSpec.describe FinitePolicyMappingDepth do
  it 'is always less than an infinite policy mapping depth' do
    expect(FinitePolicyMappingDepth.new(1) <=> InfinitePolicyMappingDepth.new).to eq(-1)
  end
end
