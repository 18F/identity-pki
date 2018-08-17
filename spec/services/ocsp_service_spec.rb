require 'rails_helper'

RSpec.describe OCSPService do
  let(:ocsp_service) { described_class.new(cert) }
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

  context 'with valid OCSP responses' do
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

      stub_request(:post, 'http://ocsp.example.com/').
        with(
          headers: {
            'Content-Type' => 'application/ocsp-request',
          }
        ).
        to_return do |request|
        {
          status: 200,
          body: create_ocsp_response(request.body, cert_collection, status),
          headers: {},
        }
      end
    end

    context 'with valid certs' do
      let(:status) { :valid }

      it 'returns false for a cert with a known ca' do
        expect(ocsp_service.call.revoked?).to eq false
      end
    end

    context 'with invalid certs' do
      let(:status) { :revoked }

      it 'returns true for a cert with a known ca' do
        expect(ocsp_service.call.revoked?).to eq true
      end
    end
  end

  context 'with invalid OCSP response' do
    let(:ca_file_path) { data_file_path('certs.pem') }

    let(:ca_file_content) do
      cert_collection.map { |info| info[:certificate] }.map(&:to_pem).join("\n\n")
    end

    let(:root_cert_key_ids) { root_certs.map(&:key_id) }

    let(:status) { :invalid }

    context "that isn't an OCSP response at all" do
      before(:each) do
        stub_request(:post, 'http://ocsp.example.com/').
          with(
            headers: {
              'Content-Type' => 'application/ocsp-request',
            }
          ).
          to_return do |_request|
          {
            status: 200,
            body: 'bad response',
            headers: {},
          }
        end
      end

      it 'returns nil' do
        expect(ocsp_service.call.revoked?).to be_nil
      end
    end

    context 'with bad data' do
      before(:each) do
        allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
        allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
          root_cert_key_ids.join(',')
        )
        certificate_store.clear_trusted_ca_root_identifiers
        certificate_store.add_pem_file(ca_file_path)

        stub_request(:post, 'http://ocsp.example.com/').
          with(
            headers: {
              'Content-Type' => 'application/ocsp-request',
            }
          ).
          to_return do |request|
          {
            status: 200,
            body: create_bad_ocsp_response(request.body, cert_collection, status, variant),
            headers: {},
          }
        end
      end

      context 'nonce' do
        let(:variant) { :nonce }

        it 'returns nil' do
          expect(ocsp_service.call.revoked?).to be_nil
        end
      end

      context 'signing_key' do
        let(:variant) { :signing_key }

        it 'returns nil' do
          expect(ocsp_service.call.revoked?).to be_nil
        end
      end
    end
  end
end
