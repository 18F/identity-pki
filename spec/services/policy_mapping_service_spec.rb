require 'rails_helper'

RSpec.describe PolicyMappingService do
  let(:service) { described_class.new(certificate) }

  let(:certificate_store) { CertificateStore.instance }

  let(:cert_collection) do
    create_certificate_set(
      root_count: 2,
      intermediate_count: 2,
      leaf_count: 2,
      root_options: {
        policy_mapping: [
          ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.42'],
          ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.43'],
          ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.44'],
        ],
      },
      intermediate_options: {
        policy_mapping: [
          ['2.16.840.1.101.2.1.11.44', '2.16.840.1.101.2.1.11.45'],
          [Certificate::ANY_POLICY, '2.16.840.1.101.2.1.11.46'],
          ['2.16.840.1.101.2.1.11.47', Certificate::ANY_POLICY],
        ],
      }
    )
  end

  let(:root_certs) { certificates_in_collection(cert_collection, :type, :root) }
  let(:intermediate_certs) { certificates_in_collection(cert_collection, :type, :intermediate) }
  let(:leaf_certs) { certificates_in_collection(cert_collection, :type, :leaf) }

  let(:ca_file_path) { data_file_path('certs.pem') }

  let(:root_cert_key_ids) { root_certs.map(&:key_id) }

  let(:ca_file_content) do
    cert_collection.map { |info| info[:certificate] }.map(&:to_pem).join("\n\n")
  end

  before(:each) do
    allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
    allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(
      root_cert_key_ids.join(',')
    )
    certificate_store.clear_trusted_ca_root_identifiers
    certificate_store.add_pem_file(ca_file_path)
  end

  let(:certificate) { leaf_certs.first }

  it 'constructs a chain from the leaf to the root' do
    expect(service.send(:chain).map(&:subject).map(&:to_s)).to eq(
      [root_certs.first.subject.to_s,
       intermediate_certs.first.subject.to_s]
    )
  end

  it 'maps the subject oid to the issuing oid' do
    expect(service.call).to eq(
      '2.16.840.1.101.2.1.11.42' => '2.16.840.1.101.3.2.1.3.7',
      '2.16.840.1.101.2.1.11.43' => '2.16.840.1.101.3.2.1.3.7',
      '2.16.840.1.101.2.1.11.44' => '2.16.840.1.101.3.2.1.3.7',
      '2.16.840.1.101.2.1.11.45' => '2.16.840.1.101.3.2.1.3.7'
    )
  end

  describe 'with a policy limiting depth' do
    let(:cert_collection) do
      create_certificate_set(
        root_count: 2,
        intermediate_count: 2,
        leaf_count: 2,
        root_options: {
          policy_mapping: [
            ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.42'],
            ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.43'],
            ['2.16.840.1.101.3.2.1.3.7', '2.16.840.1.101.2.1.11.44'],
          ],
          policy_constraints: [
            %w[inhibitPolicyMapping 0],
          ],
        },
        intermediate_options: {
          policy_mapping: [
            ['2.16.840.1.101.2.1.11.44', '2.16.840.1.101.2.1.11.45'],
          ],
        }
      )
    end

    it 'maps the subject oid to the issuing oid' do
      expect(service.call).to eq(
        '2.16.840.1.101.2.1.11.42' => '2.16.840.1.101.3.2.1.3.7',
        '2.16.840.1.101.2.1.11.43' => '2.16.840.1.101.3.2.1.3.7',
        '2.16.840.1.101.2.1.11.44' => '2.16.840.1.101.3.2.1.3.7'
      )
    end
  end
end
