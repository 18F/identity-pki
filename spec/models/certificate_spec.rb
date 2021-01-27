require 'rails_helper'

RSpec.describe Certificate do
  let(:certificate) { described_class.new(x509_cert) }

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

  before(:each) do
    described_class.clear_revocation_cache
    OCSPService.clear_ocsp_response_cache
    stub_request(:post, 'http://ocsp.example.com/').
      with(
        headers: {
          'Content-Type' => 'application/ocsp-request',
        }
      ).
      to_return do |request|
      {
        status: 200,
        body: create_ocsp_response(request.body, cert_collection, status, valid_ocsp),
        headers: {},
      }
    end
  end

  describe 'expired?' do
    let(:expired_cert) do
      root_ca, root_key = create_root_certificate(
        dn: 'CN=something',
        serial: 1
      )
      create_leaf_certificate(
        ca: root_ca,
        ca_key: root_key,
        dn: 'CN=else',
        serial: 1,
        not_after: Time.zone.now - 1.day,
        not_before: Time.zone.now - 1.week
      )
    end

    describe 'for an expired cert' do
      let(:x509_cert) { expired_cert }

      it { expect(certificate.expired?).to be_truthy }
    end

    describe 'for an unexpired cert' do
      let(:x509_cert) { root_cert }

      it { expect(certificate.expired?).to be_falsey }
    end
  end

  describe '#signature_verified?' do
    let(:x509_cert) { leaf_cert }

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
      certificate_store.clear_root_identifiers
      certificate_store.add_pem_file(ca_file_path)
    end

    context 'for an expired intermediate certificate' do
      let(:cert_collection) do
        create_certificate_set(
          root_count: 2,
          intermediate_count: 2,
          leaf_count: 2,
          intermediate_options: {
            not_after: Time.zone.now - 1.day,
            not_before: Time.zone.now - 1.week,
          }
        )
      end

      it 'has invalid intermediates' do
        expect(intermediate_certs.any?(&:valid?)).to be_falsey
      end

      it 'is invalid' do
        expect(certificate.signature_verified?).to be_falsey
      end
    end

    context 'for a valid intermediate certificate' do
      let(:x509_cert) { intermediate_cert }

      it 'has valid intermediates' do
        expect(intermediate_certs.all?(&:valid?)).to be_truthy
      end

      it 'is valid' do
        expect(certificate.signature_verified?).to be_truthy
      end

      it 'has subjectInfoAccess information' do
        expect(certificate.subject_info_access).to_not be_nil
        expect(certificate.subject_info_access).to have_key 'CA Repository'
        expect(certificate.subject_info_access['CA Repository'].count).to eq 1
      end
    end

    context 'for a intermediate certificate fetched from the IssuingCaService' do
      it 'is valid if the policy OIDs are recognized and allowed' do
        # Simulate the intermediate cert not being present in the certificate store
        intermediate_cert = CertificateStore.instance.delete(certificate.signing_key_id)

        expect(IssuingCaService).to receive(
          :fetch_signing_key_for_cert,
        ).with(certificate).and_return(intermediate_cert)

        expect(certificate.signature_verified?).to be_truthy
      end
    end
  end

  describe '#pem_filename' do
    let(:x509_cert) { leaf_cert }

    it 'formats the subject to match our naming conventions' do
      expect(certificate.pem_filename).to eq('DC=com DC=example OU=foo CN=bar 0.pem')
    end
  end

  describe 'to_pem' do
    let(:pem) { certificate.to_pem.split(/\n/) }
    let(:x509_cert) { leaf_cert }

    it 'has a subject line' do
      expect(pem).to include(/^Subject:/)
    end

    it 'has an issuer line' do
      expect(pem).to include(/^Issuer:/)
    end
  end

  describe 'auth_cert?' do
    let(:x509_cert) { leaf_cert }

    it 'returns false when the cert is not the auth cert' do
      expect(certificate.auth_cert?).to be_falsey
    end

    it 'returns true when the cert is the auth cert' do
      ext = OpenSSL::X509::Extension.new('extendedKeyUsage', '1.3.6.1.5.2.3.4')
      x509_cert.add_extension(ext)

      expect(certificate.auth_cert?).to be_truthy
    end
  end

  describe '#ocsp_http_url' do
    let(:x509_cert) { leaf_cert }

    it 'has an OCSP url' do
      expect(certificate.ocsp_http_url).to be_present
    end

    context 'with no AIA extension' do
      before(:each) do
        allow(certificate).to receive(:aia).and_return(nil)
      end

      it 'returns nil' do
        expect(certificate.ocsp_http_url).to be_nil
      end
    end
  end

  describe '#ca_issuer_http_url' do
    let(:x509_cert) { leaf_cert }

    it 'has an OCSP url' do
      expect(certificate.ca_issuer_http_url).to be_present
    end

    context 'with no AIA extension' do
      before(:each) do
        allow(certificate).to receive(:aia).and_return(nil)
      end

      it 'returns nil' do
        expect(certificate.ca_issuer_http_url).to be_nil
      end
    end
  end

  describe 'a root cert' do
    let(:x509_cert) { root_cert }

    it { expect(certificate.ca_capable?).to be_truthy }
    it { expect(certificate.self_signed?).to be_truthy }
    it { expect(certificate.valid?).to be_falsey }
    it { expect(certificate_error).to eq 'certificate.self-signed cert' }
  end

  describe 'a leaf cert' do
    let(:x509_cert) { leaf_cert }
    it { expect(certificate.ca_capable?).to be_falsey }
    it { expect(certificate.self_signed?).to be_falsey }

    it 'has authorityInfoAccess information' do
      expect(certificate.aia).to_not be_nil
      expect(certificate.aia).to have_key 'CA Issuers'
      expect(certificate.aia['CA Issuers'].count).to eq 1
      expect(certificate.aia).to have_key 'OCSP'
      expect(certificate.aia['OCSP'].count).to eq 1
    end

    describe '#logging_filename' do
      it 'includes keys and serial number' do
        expect(certificate.logging_filename).to eq [
          certificate.key_id,
          certificate.signing_key_id,
          certificate.serial,
        ].join('::')
      end
    end

    describe '#logging_content' do
      it 'includes the plaintext and the PEM form' do
        expect(certificate.logging_content).to eq [
          certificate.to_text,
          certificate.to_pem,
        ].join("\n\n")
      end
    end

    describe '#signing_key_id' do
      it 'handles multiline authorityKeyIdentifier' do
        # stub multiline aKI
        expect(certificate).to receive(:get_extension).with('authorityKeyIdentifier').and_return(
          <<~CERT
            keyid:cf:ab:b1:cf:b3:eb:28:e2:e0:c7:24:75:72:3b:f5:b6:31:18:77:6f
            DirName:/CN=my test CA
            serial:89:20:39:72:B8:50:56:5E
          CERT
        )
        expect(certificate.signing_key_id).to eq(
          'CF:AB:B1:CF:B3:EB:28:E2:E0:C7:24:75:72:3B:F5:B6:31:18:77:6F'
        )
      end
    end
  end

  describe 'a cert with no trusted cert in cert store' do
    let(:x509_cert) { leaf_cert }
    let(:unrecognized_certificate_authority) do
      UnrecognizedCertificateAuthority.find_by(key: certificate.signing_key_id)
    end

    it 'logs the cert in the unknown certificate authority table' do
      expect(certificate.signature_verified?).to be_falsey
      expect(unrecognized_certificate_authority).to_not be_nil
      expect(unrecognized_certificate_authority.dn).to eq certificate.issuer.to_s
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
      certificate_store.clear_root_identifiers
      certificate_store.add_pem_file(ca_file_path)
    end

    it { expect(certificate.revoked?).to be_truthy }

    it 'logs to S3' do
      expect(CertificateLoggerService).to receive(:log_ocsp_response)
      certificate.revoked?
    end

    it 'adds the serial number to the list of revoked serials' do
      expect { certificate.revoked? }.to change { CertificateRevocation.count }.by(1)
    end

    describe 'but with a "malformed" ocsp request' do
      let(:valid_ocsp) { false }

      it { expect(certificate.revoked?).to be_falsey }

      it 'logs to S3' do
        expect(CertificateLoggerService).to receive(:log_ocsp_response)
        certificate.revoked?
      end
    end
  end

  describe 'a verified cert with no expected policies' do
    let(:cert_collection) do
      create_certificate_set(
        root_count: 1,
        intermediate_count: 1,
        leaf_count: 1,
        leaf_options: {
          no_policies: true,
        }
      )
    end

    let(:x509_cert) { leaf_cert }

    let(:ca_file_path) { data_file_path('certs.pem') }

    let(:root_cert_key_id) { Certificate.new(root_cert).key_id }
    let(:intermediate_cert_key_id) { Certificate.new(intermediate_cert).key_id }

    let(:ca_file_content) { [root_cert, intermediate_cert].map(&:to_pem).join("\n\n") }

    let(:certificate_store) { CertificateStore.instance }

    before(:each) do
      allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
      allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
        root_cert_key_id
      )
      certificate_store.clear_root_identifiers
      certificate_store.add_pem_file(ca_file_path)
    end

    context 'when its intermediate certs are in the CertificateStore' do
      it 'verifies the certificate' do
        expect(certificate.valid?(is_leaf: true)).to be_truthy
      end

      it 'logs the cert in S3 when creating a token' do
        expect(CertificateLoggerService).to receive(:log_certificate).with(certificate)
        certificate.token({})
      end
    end

    context 'when its intermediate certs must be fetched from a CA issuer URL' do
      it 'does not verify the certificate' do
        intermediate_cert = CertificateStore.instance.delete(certificate.signing_key_id)
        expect(IssuingCaService).to receive(
          :fetch_signing_key_for_cert,
        ).with(certificate).and_return(intermediate_cert)

        expect(certificate.valid?(is_leaf: true)).to be_falsey
      end

      it 'logs the cert in S3 when creating a token' do
        intermediate_cert = CertificateStore.instance.delete(certificate.signing_key_id)
        expect(IssuingCaService).to receive(
          :fetch_signing_key_for_cert,
        ).twice.with(certificate).and_return(intermediate_cert)

        expect(CertificateLoggerService).to receive(:log_certificate).with(certificate)
        certificate.token({})
      end
    end
  end
end
