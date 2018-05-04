require 'rails_helper'
require 'uri'

RSpec.describe VerifyController, type: :controller do
  let(:token) do
    TokenService.box(token_contents)
  end

  let(:token_contents) do
    {
      'token' => 'value',
    }
  end

  describe 'POST /' do
    it 'without a token returns an error' do
      post :open
      expect(response).to be_successful

      data = JSON.parse(response.body)
      expect(data).to eq('error' => 'token.missing')
    end

    it 'returns the contents of the token' do
      post :open, params: { token: token }
      expect(response).to be_successful

      data = JSON.parse(response.body)
      expect(data).to eq token_contents
    end

    describe 'with a bad token' do
      let(:token) { SecureRandom.base64(123) }

      it 'returns an error' do
        post :open, params: { token: token }
        expect(response).to be_successful

        data = JSON.parse(response.body)
        expect(data).to eq('error' => 'token.invalid')
      end
    end
  end
end
