require 'rails_helper'

RSpec.describe CertificateChainService do
  let(:first_signing_key_id) { +'8C:D6:D4:69:A9:E4:85:41:3A:6A:A6:5E:DA:51:1A:17:8D:92:8B:6C' }
  let(:certificate_set) do
    create_certificate_set(
      root_count: 1, intermediate_count: 1, leaf_count: 1,
    )
  end

  let(:starting_cert) do
    instance_double(Certificate,
                    signing_key_id: first_signing_key_id,
                    ca_issuer_http_url: 'http://crls.pki.state.gov/AIA/CertsIssuedToDoSPIVCA2.p7c')
  end

  subject(:service) { CertificateChainService.new }

  # for a URL like http://aia.certipath.com/CertiPathBridgeCA-G3.p7c
  # the fixture is expected to be spec/fixures/CertiPathBridgeCA-G3.p7c
  def stub_p7c(url)
    fixture = File.basename(url)

    stub_request(:get, url)
      .to_return(body: File.read(File.join('spec/fixtures/', fixture)))
  end

  before do
    allow(service).to receive(:puts)
    stub_const('STDERR', instance_double('IO', puts: nil))

    stub_p7c('http://crls.pki.state.gov/AIA/CertsIssuedToDoSPIVCA2.p7c')
    stub_p7c('http://crls.pki.state.gov/AIA/CertsIssuedToDoSADRootCA.p7c')
    stub_p7c('http://http.fpki.gov/fcpca/caCertsIssuedTofcpca.p7c')
    stub_p7c('http://repo.fpki.gov/bridge/caCertsIssuedTofbcag4.p7c')
    stub_p7c('http://aia.certipath.com/CertiPathBridgeCA-G3.p7c')
    stub_p7c('http://crl.boeing.com/crl/BoeingPCAG3.p7c')
  end

  describe '#debug' do
    it 'prints the key_id for the issuers' do
      expect(service).to receive(:puts).
        with('key_id: 8C:D6:D4:69:A9:E4:85:41:3A:6A:A6:5E:DA:51:1A:17:8D:92:8B:6C')
      expect(service).to receive(:puts).
        with('key_id: CC:00:68:61:A6:A5:03:93:10:0A:1B:61:B7:87:18:C1:45:56:DA:82')

      service.debug(starting_cert)
    end
  end

  describe '#missing' do
    it 'checks for certs missing from the CertificateStore' do
      missing = service.missing(starting_cert)

      expect(missing).to all(be_kind_of(Certificate))
    end
  end

  describe '#get_cert_from_issuer' do
    it 'parses a DER-encoded x509 response when issuer url does not return PKCS7' do
      intermediate_cert = certificates_in_collection(certificate_set, :type, :intermediate).first
      key_id = intermediate_cert.key_id
      issuer_url = 'http://example.com/DODIDCA_80.cer'

      stub_request(:get, issuer_url).to_return(body: intermediate_cert.x509_cert.to_der)

      fetched_cert = service.send(:get_cert_from_issuer, key_id, issuer_url)

      expect(fetched_cert).to be_a(Certificate)
      expect(fetched_cert.key_id).to eq(key_id)
    end
  end
end
