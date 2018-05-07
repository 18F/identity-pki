require 'rails_helper'
require 'uri'

RSpec.describe IdentifyController, type: :controller do
  let(:token) do
    Rack::Utils.parse_nested_query(URI(response.get_header('Location')).query)['token']
  end

  let(:token_contents) do
    TokenService.open(token)
  end

  describe 'GET /' do
    it 'without a referrer returns http bad request' do
      get :create
      expect(response).to have_http_status(:bad_request)
    end

    describe 'with a referrer' do
      before(:each) do
        @request.headers['Referer'] = 'http://example.com/'
      end

      it 'with no certificate returns a redirect with a token' do
        get :create, params: { nonce: '123' }
        expect(response).to have_http_status(:found)
        expect(response.has_header?('Location')).to be_truthy
        expect(token).to be_truthy
        expect(token_contents['error']).to eq 'certificate.none'
        expect(token_contents['nonce']).to eq '123'
      end

      it 'with bad certificate content' do
        # sufficient for the OpenSSL library to throw an error when parsing the content
        @request.headers['X-Client-Cert'] = 'BAD CERT CONTENT'
        get :create, params: { nonce: '123' }
        expect(response).to have_http_status(:found)
        expect(response.has_header?('Location')).to be_truthy
        expect(token).to be_truthy
        expect(token_contents['error']).to eq 'certificate.bad'
        expect(token_contents['nonce']).to eq '123'
      end

      describe 'with a good certificate' do
        let(:certificate_store) { CertificateStore.instance }

        let(:root_cert_and_key) do
          create_root_certificate(
            dn: 'O=somewhere, OU=someplace, CN=something',
            serial: 1,
            not_after: Time.zone.now + 1.week,
            not_before: Time.zone.now - 1.week
          )
        end

        let(:root_cert) { root_cert_and_key.first }
        let(:root_key) { root_cert_and_key.last }

        let(:client_subject) { 'CN=other,OU=someplace,O=somewhere' }

        let(:expired_at) { Time.zone.now + 1.week }

        let(:client_cert) do
          create_leaf_certificate(
            dn: client_subject,
            serial: 1,
            ca: root_cert,
            ca_key: root_key,
            not_after: expired_at,
            not_before: Time.zone.now - 1.week
          )
        end

        let(:client_cert_pem) { client_cert.to_pem }

        let(:ca_file_path) { data_file_path('certs.pem') }

        let(:root_cert_key_ids) do
          [root_cert.extensions.detect { |x| x.oid == 'subjectKeyIdentifier' }.value]
        end

        let(:ca_file_content) { root_cert.to_pem }

        before(:each) do
          # create signing cert
          allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
          allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
            root_cert_key_ids.join(',')
          )
          certificate_store.clear_trusted_ca_root_identifiers
          certificate_store.add_pem_file(ca_file_path)
        end

        it 'returns a token with a uuid and subject' do
          @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
          get :create, params: { nonce: '123' }
          expect(response).to have_http_status(:found)
          expect(response.has_header?('Location')).to be_truthy
          expect(token).to be_truthy

          expect(token_contents['nonce']).to eq '123'

          # N.B.: we do this split/sort because DNs match without respect to
          # ordering of components. OpenSSL::X509::Name doesn't match correctly.
          given_subject = token_contents['subject'].split(/\s*,\s*/).sort
          expected_subject = client_subject.split(/\s*,\s*/).sort
          expect(given_subject).to eq expected_subject
        end

        describe 'with an expired certificate' do
          let(:expired_at) { Time.zone.now - 1.day }

          it 'returns a token as expired' do
            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
            get :create, params: { nonce: '123' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.expired'
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'with a revoked certificate' do
          it 'returns a token as revoked' do
            ca = CertificateAuthority.find_or_create_for_certificate(
              Certificate.new(root_cert)
            )
            ca.certificate_revocations.create(serial: '1')

            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
            get :create, params: { nonce: '123' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.revoked'
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'a certificate signed by an unrecognized authority' do
          let(:other_root_cert_and_key) do
            create_root_certificate(
              dn: 'O=somewhere, OU=someplace, CN=something',
              serial: 1,
              not_after: Time.zone.now + 1.week,
              not_before: Time.zone.now - 1.week
            )
          end

          let(:other_root_cert) { other_root_cert_and_key.first }
          let(:other_root_key) { other_root_cert_and_key.last }

          let(:client_cert) do
            create_leaf_certificate(
              dn: client_subject,
              serial: 1,
              ca: other_root_cert,
              ca_key: other_root_key,
              not_after: expired_at,
              not_before: Time.zone.now - 1.week
            )
          end

          it 'returns a token as unverified' do
            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
            get :create, params: { nonce: '123' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.unverified'
            expect(token_contents['nonce']).to eq '123'
          end
        end
      end
    end
  end
end
