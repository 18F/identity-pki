require 'rails_helper'

RSpec.describe Health::OverallController do
  describe '#index' do
    it 'is a plaintex success response' do
      get :index
      expect(response.body).to eq('success')
      expect(response).to be_successful
      expect(response.content_type).to eq('text/plain; charset=utf-8')
    end
  end
end
