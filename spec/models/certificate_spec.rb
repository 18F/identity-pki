require 'rails_helper'

RSpec.describe Certificate do
  let(:certificate) { described_class.new(x509_cert) }

  let(:cert_collection) do
    create_certificate_set(
      root_count: 1,
      intermediate_count: 1,
      leaf_count: 1
    )
  end

  let(:root_cert) { cert_collection.first.first }
  let(:intermediate_cert) { cert_collection[1].first }
  let(:leaf_cert) { cert_collection.last.first }

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

  describe 'a root cert' do
    let(:x509_cert) { root_cert }

    it { expect(certificate.ca_capable?).to be_truthy }
    it { expect(certificate.self_signed?).to be_truthy }
  end

  describe 'a leaf cert' do
    let(:x509_cert) { leaf_cert }

    it { expect(certificate.ca_capable?).to be_falsey }
    it { expect(certificate.self_signed?).to be_falsey }
  end
end
