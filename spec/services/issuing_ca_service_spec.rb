require 'rails_helper'

RSpec.describe IssuingCaService do
  before do
    allow(described_class).to receive(:ca_issuer_host_allow_list).and_return(['example.com'])

    described_class.clear_ca_certificates_response_cache!
  end

  describe '.fetch_signing_key_for_cert' do
    context 'when the the signing key is available at the issuer url' do
      it 'returns the certificate' do
        certificate_set = create_certificate_set(
          root_count: 1, intermediate_count: 1, leaf_count: 1,
        )
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        signing_cert = certificates_in_collection(certificate_set, :type, :intermediate).first

        pkcs7_bundle = OpenSSL::PKCS7.new
        pkcs7_bundle.type = 'signed'
        pkcs7_bundle.add_certificate(signing_cert.x509_cert)
        pkcs7_bundle.add_data("")
        pkcs7_response_body = pkcs7_bundle.to_der

        stub_request(:get, 'http://example.com').to_return(body: pkcs7_response_body)

        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)

        expect(fetched_cert).to eq(signing_cert)
      end
    end

    context 'when called twice for the same issuing certificate' do
      it 'caches the response and does not make a second request'
    end

    context 'when a URI has a host that is not in the allow list' do
      it 'logs and does not make a request to that host'
    end

    context 'when there is an HTTP error fetching the certificate' do
      it 'returns nil and logs the error'
    end

    context 'when the PKCS7 response is invalid' do
      it 'returns nil and logs the error'
    end

    context 'when the certificate does not have and CA Issuer URIs' do
      it 'returns nil'
    end

    context 'when the certificate does not have authority information access' do
      it 'returns nil'
    end
  end
end
