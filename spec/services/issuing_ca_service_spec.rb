require 'rails_helper'

RSpec.describe IssuingCaService do
  before do
    allow(described_class).to receive(:ca_issuer_host_allow_list).and_return(['example.com'])
  end

  let(:certificate_set) do
    create_certificate_set(
      root_count: 1, intermediate_count: 1, leaf_count: 1,
    )
  end

  describe '.fetch_signing_key_for_cert' do
    context 'when the signing key is available at the issuer url' do
      it 'returns the certificate' do
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        signing_cert = certificates_in_collection(certificate_set, :type, :intermediate).first

        pkcs7_bundle = build_pkc7_bundle(signing_cert.x509_cert)
        stub_request(:get, 'http://example.com').to_return(body: pkcs7_bundle.to_der)

        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)

        expect(fetched_cert).to eq(signing_cert)
      end
    end

    context 'when called twice for the same issuing certificate' do
      it 'caches the response and does not make a second request' do
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        signing_cert = certificates_in_collection(certificate_set, :type, :intermediate).first

        pkcs7_bundle = build_pkc7_bundle(signing_cert.x509_cert)
        stub_request(:get, 'http://example.com').to_return(body: pkcs7_bundle.to_der)

        fetched_cert1 = described_class.fetch_signing_key_for_cert(certificate)
        fetched_cert2 = described_class.fetch_signing_key_for_cert(certificate)

        expect(fetched_cert1).to eq(signing_cert)
        expect(fetched_cert2).to eq(signing_cert)
        expect(a_request(:get, 'http://example.com')).to have_been_made.once
      end
    end

    context 'when a URI has a host that is not in the allow list' do
      it 'logs and does not make a request to that host' do
        allow(described_class).to receive(:ca_issuer_host_allow_list).and_return(['example2.com'])

        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        expect(Rails.logger).to receive(:info).with('CA Issuer Host Not Allowed: example.com')
        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)
        expect(fetched_cert).to eq nil
      end
    end

    context 'when there is an HTTP error fetching the certificate' do
      it 'returns nil and logs the error' do
        stub_request(:get, 'http://example.com/').to_return(
          status: [500, 'Internal Server Error'],
          body: 'Internal Server Error',
        )

        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        expect(NewRelic::Agent).to receive(:notice_error).with(
          IssuingCaService::UnexpectedPKCS7Response.new('Internal Server Error'),
          custom_params: { issuer_uri: 'http://example.com/' },
        )
        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)
        expect(fetched_cert).to eq nil
      end
    end

    context 'when there is an HTTP timeout fetching the certificate' do
      it 'returns nil and logs the error' do
        stub_request(:get, 'http://example.com/').to_timeout

        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        expect(NewRelic::Agent).to receive(:notice_error).with(
          Net::OpenTimeout,
          custom_params: {
            issuer_uri: 'http://example.com/',
            response_body: nil,
          },
        )
        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)
        expect(fetched_cert).to eq nil
      end
    end

    context 'when the PKCS7 response is invalid' do
      it 'returns nil and logs the error' do
        stub_request(:get, 'http://example.com/').to_return(body: 'bad pkcs7 response')

        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        expect(NewRelic::Agent).to receive(:notice_error).with(
          ArgumentError,
          custom_params: {
            issuer_uri: 'http://example.com/',
            response_body: 'bad pkcs7 response',
          },
        )
        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)
        expect(fetched_cert).to eq nil
      end
    end

    context 'when issuer uri returns x509 certificate' do
      it 'returns the x509 cert still as a collection' do
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        signing_cert = certificates_in_collection(certificate_set, :type, :intermediate).first

        stub_request(:get, 'http://example.com').to_return(body: signing_cert.x509_cert.to_der)

        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)

        expect(fetched_cert).to eq(signing_cert)
        expect(a_request(:get, 'http://example.com')).to have_been_made.once
      end
    end

    context 'when the certificate does not have and CA Issuer URIs' do
      it 'returns nil' do
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        certificate.x509_cert
      end
    end

    context 'when the certificate does not have authority information access' do
      it 'returns nil' do
        certificate = certificates_in_collection(certificate_set, :type, :leaf).first
        allow(certificate).to receive(:aia).and_return({})
        fetched_cert = described_class.fetch_signing_key_for_cert(certificate)
        expect(fetched_cert).to eq nil
      end
    end
  end

  describe '.certificate_store_issuers' do
    it 'allowed hosts configuration contains all certificate store issuers' do
      CertificateStore.reset
      CertificateStore.instance.load_certs!(dir: Rails.root.join('config/certs'))
      configuration = YAML.load_file('config/application.yml.default')
      prod_issuer_allow_list = configuration.dig('ca_issuer_host_allow_list').split(',').sort.to_set
      stored_issuers = described_class.certificate_store_issuers.map(&:host).sort.to_set

      expect(stored_issuers - prod_issuer_allow_list).to be_empty
    end
  end

  describe '.fetch_ca_repository_certs_for_cert' do
    context 'when the cert has a subject information access extension with Repository CA' do
      it 'returns the certificate' do
        certificate = certificates_in_collection(certificate_set, :type, :intermediate).first
        sibling_cert = certificates_in_collection(certificate_set, :type, :intermediate).last

        pkcs7_bundle = build_pkc7_bundle(sibling_cert.x509_cert)
        stub_request(:get, 'http://example.com').to_return(body: pkcs7_bundle.to_der)

        fetched_certs = described_class.fetch_ca_repository_certs_for_cert(certificate)

        expect(fetched_certs).to eq([sibling_cert])
      end
    end
  end

  def build_pkc7_bundle(x509_cert)
    pkcs7_bundle = OpenSSL::PKCS7.new
    pkcs7_bundle.type = 'signed'
    pkcs7_bundle.add_certificate(x509_cert)
    pkcs7_bundle.add_data('')
    pkcs7_bundle
  end
end
