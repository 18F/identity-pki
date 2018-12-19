require 'rails_helper'

RSpec.describe OCSPResponse do
  let(:ocsp_response) { described_class.new(service_request, response) }
  let(:certificate) { Certificate.new(x509_cert) }

  let(:certificate_error) do
    TokenService.open(
      certificate.send(:token_for_invalid_certificate, {})
    )['error']
  end

  let(:certificate_store) { CertificateStore.instance }

  let(:cert_collection) do
    create_certificate_set(
      root_count: 2,
      intermediate_count: 2,
      leaf_count: 2
    )
  end

  let(:root_certs) { certificates_in_collection(cert_collection, :type, :root) }
  let(:intermediate_certs) { certificates_in_collection(cert_collection, :type, :intermediate) }
  let(:leaf_certs) { certificates_in_collection(cert_collection, :type, :leaf) }
  let(:cert) { leaf_certs.first }

  let(:root_cert) { root_certs.first.x509_cert }
  let(:intermediate_cert) { intermediate_certs.first.x509_cert }
  let(:leaf_cert) { leaf_certs.first.x509_cert }
  let(:status) { :valid }
  let(:valid_ocsp) { true }

  let(:service_request) do
    service = OCSPService.new(certificate)
    service.send(:build_request)
    service
  end

  let(:request_der) { service_request.request.to_der }

  let(:response) do
    OpenSSL::OCSP::Response.new(
      create_ocsp_response(request_der, cert_collection, status, valid_ocsp)
    )
  end

  let(:ca_file_path) { data_file_path('certs.pem') }

  let(:ca_file_content) do
    cert_collection.map { |info| info[:certificate] }.map(&:to_pem).join("\n\n")
  end

  let(:root_cert_key_ids) { root_certs.map(&:key_id) }
  before(:each) do
    allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
    allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
      root_cert_key_ids.join(',')
    )
    certificate_store.clear_trusted_ca_root_identifiers
    certificate_store.add_pem_file(ca_file_path)
  end

  context 'a leaf cert' do
    let(:x509_cert) { leaf_cert }

    describe 'to_pem' do
      let(:pem) { ocsp_response.to_pem.split(/\n/) }

      it 'has a preamble line' do
        expect(pem).to include('----- BEGIN OCSP -----')
      end

      it 'has a postamble line' do
        expect(pem).to include('----- END OCSP -----')
      end
    end

    describe 'to_text' do
      let(:text) { ocsp_response.to_text }

      it 'has the subject certificate serial number' do
        expect(text).to include("Serial: #{certificate.serial}")
      end
    end

    describe '#logging_filename' do
      it 'includes keys and serial number' do
        expect(ocsp_response.logging_filename).to eq 'OCSP:' + [
          certificate.key_id,
          certificate.signing_key_id,
          certificate.serial,
        ].join('::')
      end
    end

    describe '#logging_content' do
      it 'includes the plaintext and the PEM form' do
        expect(ocsp_response.logging_content).to eq [
          certificate.to_pem,
          ocsp_response.to_pem,
          ocsp_response.to_text,
        ].join("\n")
      end
    end
  end

  describe 'a cert that is revoked via ocsp' do
    let(:status) { :revoked }
    let(:x509_cert) { leaf_cert }
    let(:ca_file_path) { data_file_path('certs.pem') }

    let(:ca_file_content) do
      cert_collection.map { |info| info[:certificate] }.map(&:to_pem).join("\n\n")
    end

    let(:root_cert_key_ids) { root_certs.map(&:key_id) }
    before(:each) do
      allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
      allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
        root_cert_key_ids.join(',')
      )
      certificate_store.clear_trusted_ca_root_identifiers
      certificate_store.add_pem_file(ca_file_path)
    end

    it { expect(ocsp_response.revoked?).to be_truthy }

    describe 'but with a "malformed" ocsp request' do
      let(:valid_ocsp) { false }

      it { expect(ocsp_response.revoked?).to be_falsey }
    end
  end
end
