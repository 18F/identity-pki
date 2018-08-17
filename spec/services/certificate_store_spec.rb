require 'rails_helper'

RSpec.describe CertificateStore do
  let(:certificate_store) { described_class.instance }

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

  describe 'with loaded certificates' do
    let(:ca_file_path) { data_file_path('certs.pem') }

    let(:root_cert_key_ids) { root_certs.map(&:key_id) }
    let(:intermediate_cert_key_ids) { intermediate_certs.map(&:key_id) }

    let(:ca_file_content) do
      cert_collection.map { |info| info[:certificate] }.map(&:to_pem).join("\n\n")
    end

    let(:cert_identifiers) do
      mapping = {}
      leaf_certs.each do |cert|
        issuer = CertificateStore.instance[cert.signing_key_id]
        certificate_id = OpenSSL::OCSP::CertificateId.new(
          cert.x509_cert, issuer.x509_cert, OpenSSL::Digest::SHA1.new
        )
        mapping[certificate_id] = {
          subject: cert,
          issuer: issuer,
        }
      end
      mapping
    end

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
          body: create_ocsp_response(request.body, cert_collection),
          headers: {},
        }
      end
    end

    describe 'all_certificates_valid?' do
      it 'is true when we only have roots and intermediate certs from those roots' do
        expect(certificate_store.all_certificates_valid?).to be_truthy
      end

      describe 'with an untrusted root' do
        before(:each) do
          allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
            root_cert_key_ids.first
          )

          certificate_store.clear_trusted_ca_root_identifiers
        end

        it 'is false' do
          expect(certificate_store.all_certificates_valid?).to be_falsey
        end

        describe 'after removing untrusted certificates' do
          before(:each) do
            certificate_store.remove_untrusted_certificates
          end

          it 'is true' do
            expect(certificate_store.all_certificates_valid?).to be_truthy
          end
        end
      end
    end

    describe 'each' do
      let(:visited_ids) do
        ids = []
        certificate_store.each do |cert|
          ids << cert.key_id
        end
        ids
      end

      let(:stored_ids) do
        cert_collection.map { |c| c[:certificate] }.select(&:ca_capable?).map(&:key_id)
      end

      it 'visits each certificate' do
        expect(visited_ids.sort).to eq stored_ids.sort
      end
    end

    describe 'loading certificates' do
      it 'loads from the file and retains signing certs' do
        expect(cert_collection.count).to eq 14
        expect(certificate_store.count).to eq 6
      end

      it 'creates Certificate objects' do
        expect(CertificateAuthority.count).to eq 6
      end
    end

    describe 'validating trusted certs' do
      describe 'trusted_ca_root_identifiers' do
        it 'reflects the configured set' do
          expect(certificate_store.send(:trusted_ca_root_identifiers)).to eq root_cert_key_ids
        end
      end

      describe 'with all of the root/intermediate certs' do
        it 'has the right chain of certs' do
          chain_ids = certificate_store.x509_certificate_chain(leaf_certs.first).map(&:key_id)

          expect(chain_ids).to eq [
            intermediate_cert_key_ids.first,
            root_cert_key_ids.first,
          ]
        end
      end

      describe 'with no intermediates' do
        let(:ca_file_content) do
          certificates_in_collection(cert_collection, :type, :root).
            map(&:to_pem).
            join("\n\n")
        end

        describe 'then the presented root' do
          let(:root_cert) { root_certs.first }

          it 'is trusted' do
            expect(root_cert.valid?).to be_truthy
          end
        end

        describe 'then the presented intermediate' do
          let(:intermediate_cert) { intermediate_certs.first }

          it 'is trusted' do
            expect(intermediate_cert.valid?).to be_truthy
          end
        end

        describe 'then the presented leaf' do
          let(:leaf_cert) { leaf_certs.first }

          it 'is untrusted' do
            expect(leaf_cert.valid?).to be_falsey
          end
        end
      end
    end
  end
end
