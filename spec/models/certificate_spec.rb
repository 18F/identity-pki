require 'rails_helper'

RSpec.describe Certificate, type: :model do
  let(:certificate) { create(:certificate, crl_http_url: crl_http_url) }
  let(:crl_http_url) {}

  subject { certificate }
  it { is_expected.to validate_uniqueness_of(:key) }
  it { is_expected.to validate_presence_of(:dn) }
  it { is_expected.to validate_presence_of(:valid_not_after) }
  it { is_expected.to validate_presence_of(:valid_not_before) }

  describe 'update_revocations' do
    it 'raises if no crl url' do
      expect do
        certificate.update_revocations
      end.to raise_error(CertificateRevocationListService::NO_CRL_URL_ERROR)
    end

    describe 'with a crl http url' do
      let(:crl_http_url) { 'http://example.com/crl' }

      let(:revoked_serials) { [] }
      let(:serials_list) { certificate.reload.certificate_revocations.pluck(:serial) }

      before(:each) do
        stub_request(:get, crl_http_url).to_return(body: 'crl_list')
        allow(OpenSSL::X509::CRL).to receive(:new).with('crl_list') do
          OpenStruct.new(
            revoked: revoked_serials.map { |s| OpenStruct.new(serial: s) }
          )
        end
      end

      it 'pulls the content via a GET' do
        certificate.update_revocations

        expect(a_request(:get, crl_http_url)).to have_been_made.once
      end

      describe 'with revoked serials' do
        let(:revoked_serials) { [1, 2, 3, 5, 7, 11] }

        let(:expected_revoked_serials_count) { revoked_serials.count }
        let(:expected_revoked_serials_list) { revoked_serials.map(&:to_s).sort }

        it 'adds them to the database' do
          certificate.update_revocations

          expect(serials_list.count).to eq expected_revoked_serials_count
          expect(serials_list.sort).to eq expected_revoked_serials_list
        end

        it 'adds them only if they are not present' do
          certificate.certificate_revocations.create!(serial: '3')

          certificate.update_revocations

          expect(serials_list.count).to eq expected_revoked_serials_count
          expect(serials_list.sort).to eq expected_revoked_serials_list
        end
      end
    end

    describe 'with fcpca crl' do
      let(:crl_http_url) { 'http://example.com/crl' }

      before(:each) do
        stub_request(:get, crl_http_url).to_return(body: data_file('fcpca.crl'))
      end

      # This list comes from using `openssl crl -in spec/data/fcpca.crl -inform DER -text`
      # to find the revoked serials in the CRL.
      let(:expected_revoked_serials_list) do
        [
          0x3ff6, 0x18b4, 0x4244, 0x02c1, 0x3dee, 0x3fec, 0x2ef8, 0x327d,
          0x4302, 0x2584, 0x423a, 0x2ca0
        ].map(&:to_s).sort
      end

      it 'loads the serial numbers' do
        certificate.update_revocations

        serials_list = certificate.reload.certificate_revocations.pluck(:serial)

        expect(serials_list.sort).to eq expected_revoked_serials_list
      end
    end
  end
end
