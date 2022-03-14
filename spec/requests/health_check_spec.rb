require 'rails_helper'

RSpec.describe 'health check requests' do
  describe '/health_check' do
    it 'serves a health check response' do
      get '/health_check'

      expect(response).to be_successful
      expect(response.body).to eq('success')
    end
  end
end
