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
    before(:each) do
      allow(Figaro.env).to receive(:piv_cac_verify_token_secret).and_return(token_secret)
    end

    let(:response_data) { JSON.parse(response.body) }

    context 'with an auth secret' do
      let(:token_secret) { 'foo' }

      context 'without an auth header' do
        it 'without a token returns an error' do
          post :open
          expect(response).to be_successful

          data = JSON.parse(response.body)
          expect(data).to eq('error' => 'token.missing')
        end

        it 'returns an auth error when given a token' do
          post :open, params: { token: token }
          expect(response).to be_successful
          expect(response.status).to eq 200
          expect(response_data['error']).to eq 'auth.required'
        end

        describe 'with a bad token' do
          let(:token) { SecureRandom.base64(123) }

          it 'returns an auth error' do
            post :open, params: { token: token }
            expect(response).to be_successful
            expect(response.status).to eq 200
            expect(response_data['error']).to eq 'token.invalid'
          end
        end
      end

      context 'with an auth header' do
        let(:nonce) { SecureRandom.hex(10) }
        let(:auth_header) do
          digest = Base64.urlsafe_encode64(
            OpenSSL::HMAC.digest('SHA256', token_secret, [token, nonce].join('+'))
          )
          "hmac :#{nonce}:#{digest}"
        end

        before(:each) do
          @request.headers['Authentication'] = auth_header
        end

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

        describe 'with a repeated nonce' do
          context 'with a bloom filter configured' do
            before(:each) do
              allow(FeatureManagement).to receive(:nonce_bloom_filter_enabled?).and_return(true)
            end

            it 'returns an auth error' do
              post :open, params: { token: token }
              expect(response).to be_successful

              post :open, params: { token: token }
              expect(response).to be_successful
              expect(response.status).to eq 200
              expect(response_data['error']).to eq 'auth.required'
            end
          end

          context 'with no bloom filter configured' do
            before(:each) do
              allow(FeatureManagement).to receive(:nonce_bloom_filter_enabled?).and_return(false)
            end

            it 'returns no auth error' do
              post :open, params: { token: token }
              expect(response).to be_successful

              post :open, params: { token: token }
              expect(response).to be_successful
              expect(response.status).to eq 200
              expect(response_data['error']).to be_nil
              expect(response_data['token']).to eq 'value'
            end
          end
        end
      end
    end

    context 'without an auth secret' do
      let(:token_secret) { '' }

      # TODO: make these all be unsuccessful
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
end
