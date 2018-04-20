require 'rails_helper'

RSpec.describe CertificateAuthority, type: :model do
  let(:authority) { create(:certificate_authority, crl_http_url: crl_http_url) }
  let(:crl_http_url) {}

  subject { authority }
  it { is_expected.to validate_uniqueness_of(:key) }
  it { is_expected.to validate_presence_of(:dn) }
  it { is_expected.to validate_presence_of(:valid_not_after) }
  it { is_expected.to validate_presence_of(:valid_not_before) }

  describe 'revoked?' do
    it 'with no revocations' do
      expect(authority.revoked?('123')).to be_falsey
    end

    describe 'with some revocations' do
      before(:each) do
        authority.certificate_revocations.create!(serial: '234')
        authority.certificate_revocations.create!(serial: '345')
      end

      it 'finds a revoked serial' do
        expect(authority.revoked?('234')).to be_truthy
      end

      it 'fails to find a serial not revoked' do
        expect(authority.revoked?('123')).to be_falsey
      end
    end
  end

  describe 'update_revocations' do
    it 'raises if no crl url' do
      expect do
        authority.update_revocations
      end.to raise_error(CertificateRevocationListService::NO_CRL_URL_ERROR)
    end

    describe 'with a crl http url' do
      let(:crl_http_url) { 'http://example.com/crl' }

      let(:revoked_serials) { [] }
      let(:serials_list) { authority.reload.certificate_revocations.pluck(:serial) }

      before(:each) do
        stub_request(:get, crl_http_url).to_return(body: 'crl_list')
        allow(OpenSSL::X509::CRL).to receive(:new).with('crl_list') do
          OpenStruct.new(
            revoked: revoked_serials.map { |s| OpenStruct.new(serial: s) }
          )
        end
      end

      it 'pulls the content via a GET' do
        authority.update_revocations

        expect(a_request(:get, crl_http_url)).to have_been_made.once
      end

      describe 'with revoked serials' do
        let(:revoked_serials) { [1, 2, 3, 5, 7, 11] }

        let(:expected_revoked_serials_count) { revoked_serials.count }
        let(:expected_revoked_serials_list) { revoked_serials.map(&:to_s).sort }

        it 'adds them to the database' do
          authority.update_revocations

          expect(serials_list.count).to eq expected_revoked_serials_count
          expect(serials_list.sort).to eq expected_revoked_serials_list
        end

        it 'adds them only if they are not present' do
          authority.certificate_revocations.create!(serial: '3')

          authority.update_revocations

          expect(serials_list.count).to eq expected_revoked_serials_count
          expect(serials_list.sort).to eq expected_revoked_serials_list
        end
      end
    end

    describe 'with a crl file' do
      let(:crl_http_url) { 'http://example.com/crl' }

      let(:signing_cert_info) do
        create_root_certificate(dn: '/DC=com/DC=example/CN=root', serial: 1)
      end

      let(:signing_cert) { signing_cert_info.first }
      let(:signing_key) { signing_cert_info.last }

      let(:crl_content) do
        create_crl(
          ca: signing_cert,
          ca_key: signing_key,
          serials: revoked_serials_list
        ).to_der
      end

      let(:revoked_serials_list) do
        [
          0x3ff6, 0x18b4, 0x4244, 0x02c1, 0x3dee, 0x3fec, 0x2ef8, 0x327d,
          0x4302, 0x2584, 0x423a, 0x2ca0
        ]
      end

      before(:each) do
        stub_request(:get, crl_http_url).to_return(body: crl_content)
      end

      # This list comes from using `openssl crl -in spec/data/fcpca.crl -inform DER -text`
      # to find the revoked serials in the CRL.
      let(:expected_revoked_serials_list) do
        revoked_serials_list.map(&:to_s).sort
      end

      it 'loads the serial numbers' do
        authority.update_revocations

        serials_list = authority.reload.certificate_revocations.pluck(:serial)

        expect(serials_list.sort).to eq expected_revoked_serials_list
      end
    end
  end
end
