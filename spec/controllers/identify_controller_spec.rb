require 'rails_helper'
require 'uri'

RSpec.describe IdentifyController, type: :controller do
  let(:token) do
    Rack::Utils.parse_nested_query(URI(response.get_header('Location')).query)['token']
  end

  let(:token_contents) do
    TokenService.open(token)
  end

  let(:ocsp_response) { false }
  let(:ocsp_responder) do
    OpenStruct.new(
      call: OpenStruct.new(revoked?: ocsp_response)
    )
  end

  before(:each) do
    Certificate.clear_revocation_cache
    OcspService.clear_ocsp_response_cache
  end

  describe 'GET /' do
    it 'without a referrer returns http bad request' do
      get :create, params: { nonce: '123' }
      expect(response).to have_http_status(:bad_request)
    end

    describe 'with a bad referrer' do
      before(:each) do
        allow(IdentityConfig.store).to receive(:identity_idp_host).and_return('example.org')
      end

      it 'returns http bad request' do
        get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe 'with a malformed referrer' do
      before(:each) do
        allow(IdentityConfig.store).to receive(:identity_idp_host).and_return('example.org')
      end

      it 'returns http bad request' do
        redirect_uri = "cast((SELECT dblink_connect('host=xyz'|" \
          "|'123.example.com user=a password=a connect_timeout=2')) as numeric)"
        get :create, params: { nonce: '123', redirect_uri: redirect_uri }
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe 'with a good referrer' do
      before(:each) do
        allow(IdentityConfig.store).to receive(:identity_idp_host).and_return('example.com')
      end

      it 'with no certificate returns a redirect with a token' do
        get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
        expect(response).to have_http_status(:found)
        expect(response.has_header?('Location')).to be_truthy
        expect(token).to be_truthy
        expect(token_contents['error']).to eq 'certificate.none'
        expect(token_contents['nonce']).to eq '123'
      end

      it 'with bad certificate content' do
        # sufficient for the OpenSSL library to throw an error when parsing the content
        @request.headers['X-Client-Cert'] = 'BAD CERT CONTENT'
        get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
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
        let(:client_issuer) do
          '/O=somewhere/OU=someplace/CN=something'
        end

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
          allow(IdentityConfig.store).to receive(:trusted_ca_root_identifiers).and_return(
            root_cert_key_ids
          )
          certificate_store.clear_root_identifiers
          certificate_store.add_pem_file(ca_file_path)
        end

        context 'when the web server sends the escaped cert' do
          before(:each) do
            allow(OcspService).to receive(:new).and_return(ocsp_responder)
          end

          it 'returns a token with a uuid and subject and logs certificate metadata' do
            allow(IdentityConfig.store).to receive(:client_cert_escaped).and_return(true)

            cert = Certificate.new(client_cert)

            expect(CertificateLoggerService).to receive(:log_certificate).once
            expect(Rails.logger).to receive(:info).with(/GET/).once
            expect(Rails.logger).to receive(:info).with(
              'Returning a token for a valid certificate.'
            ).once
            expect(Rails.logger).to receive(:info).with({
              name: 'Certificate Processed',
              signing_key_id: cert.signing_key_id,
              key_id: cert.key_id,
              certificate_chain_signing_key_ids: [cert.signing_key_id],
              issuer: cert.issuer.to_s,
              valid_policies: true,
              valid: true,
              error: nil,
              openssl_valid: false,
              openssl_errors: 'error 20 at 0 depth lookup: unable to get local issuer certificate',
              ficam_openssl_valid: false,
              ficam_openssl_errors: 'error 20 at 0 depth lookup: unable to get local issuer certificate',
            }.to_json).once

            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)


            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['nonce']).to eq '123'

            # N.B.: we do this split/sort because DNs match without respect to
            # ordering of components. OpenSSL::X509::Name doesn't match correctly.
            given_subject = token_contents['subject'].split(/\s*,\s*/).sort
            expected_subject = client_subject.split(/\s*,\s*/).sort
            expect(given_subject).to eq expected_subject

            expect(token_contents['issuer']).to eq(client_issuer)
          end

          it 'allows the use of the REFERRER header to specify the referrer' do
            allow(IdentityConfig.store).to receive(:client_cert_escaped).and_return(true)
            @request.headers['Referer'] = 'http://example.com/'
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
        end

        context 'when the web server sends an unescaped cert' do
          before(:each) do
            allow(OcspService).to receive(:new).and_return(ocsp_responder)
          end

          it 'returns a token with a uuid and subject' do
            allow(IdentityConfig.store).to receive(:client_cert_escaped).and_return(false)
            @request.headers['X-Client-Cert'] = client_cert_pem.split(/\n/).join("\n\t")
            expect(CertificateLoggerService).to receive(:log_certificate).once

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['nonce']).to eq '123'

            # N.B.: we do this split/sort because DNs match without respect to
            # ordering of components. OpenSSL::X509::Name doesn't match correctly.
            expect(token_contents['subject']).to_not be_nil
            given_subject = token_contents['subject'].split(/\s*,\s*/).sort
            expected_subject = client_subject.split(/\s*,\s*/).sort
            expect(given_subject).to eq expected_subject
          end
        end

        describe 'with an expired certificate' do
          let(:expired_at) { Time.zone.now - 1.day }

          it 'returns a token as expired' do
            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
            expect(CertificateLoggerService).to receive(:log_certificate)
            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.expired'
            expect(token_contents['key_id']).to be_present
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'with a revoked certificate' do
          before(:each) do
            stub_request(:post, 'http://ocsp.example.com/').
              to_return(status: 400, body: '', headers: {})
          end

          it 'returns a token as revoked' do
            ca = CertificateAuthority.find_or_create_for_certificate(
              Certificate.new(root_cert)
            )
            ca.certificate_revocations.create(serial: client_cert.serial)

            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)
            expect(CertificateLoggerService).to receive(:log_certificate)

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.revoked'
            expect(token_contents['key_id']).to be_present
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'with a certificate timeout' do
          before(:each) do
            stub_request(:post, 'http://ocsp.example.com/').to_timeout
          end

          it 'returns a valid response after checking CRLs' do
            ca = CertificateAuthority.find_or_create_for_certificate(
                Certificate.new(root_cert)
            )

            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to be_nil
            expect(token_contents['uuid']).to be_present
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'with a certificate ocsp error' do
          before(:each) do
            stub_request(:post, 'http://ocsp.example.com/').
              to_return(status: 200, body: 'not-a-valid-cert', headers: {})
          end

          it 'returns a valid response after checking CRLs' do
            ca = CertificateAuthority.find_or_create_for_certificate(
                Certificate.new(root_cert)
            )

            @request.headers['X-Client-Cert'] = CGI.escape(client_cert_pem)

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to be_nil
            expect(token_contents['uuid']).to be_present
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
            expect(CertificateLoggerService).to receive(:log_certificate)

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.unverified'
            expect(token_contents['key_id']).to be_present
            expect(token_contents['nonce']).to eq '123'
          end
        end

        describe 'a self-signed certificate' do
          it 'returns a token as self-signed and does not log issuer' do
            cert = Certificate.new(root_cert)
            @request.headers['X-Client-Cert'] = CGI.escape(root_cert.to_pem)
            expect(CertificateLoggerService).to receive(:log_certificate)
            expect(Rails.logger).to receive(:info).with(/GET/).once
            expect(Rails.logger).to receive(:info).with({
              name: 'Certificate Processed',
              signing_key_id: cert.key_id,
              key_id: cert.key_id,
              certificate_chain_signing_key_ids: [cert.signing_key_id],
              valid_policies: false,
              valid: false,
              error: 'self-signed cert',
              openssl_valid: false,
              openssl_errors: 'error 18 at 0 depth lookup: self signed certificate, error 26 at 0 depth lookup: unsupported certificate purpose',
              ficam_openssl_valid: false,
              ficam_openssl_errors: 'error 18 at 0 depth lookup: self signed certificate, error 26 at 0 depth lookup: unsupported certificate purpose',
            }.to_json).once

            get :create, params: { nonce: '123', redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:found)
            expect(response.has_header?('Location')).to be_truthy
            expect(token).to be_truthy

            expect(token_contents['error']).to eq 'certificate.self-signed cert'
            expect(token_contents['key_id']).to be_present
            expect(token_contents['nonce']).to eq '123'
          end
        end


        context 'when the nonce param is missing' do
          it 'returns a bad request' do
            get :create, params: { redirect_uri: 'http://example.com/' }
            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end
end
