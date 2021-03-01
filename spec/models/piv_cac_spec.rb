require 'rails_helper'

RSpec.describe PivCac, type: :model do
  let(:piv_cac) { create(:piv_cac) }

  subject { piv_cac }
  it { is_expected.to validate_presence_of :uuid }
  it { is_expected.to validate_uniqueness_of :uuid }
  it { is_expected.to validate_presence_of :dn_signature }
  it { is_expected.to validate_uniqueness_of :dn_signature }

  describe '#find_or_create_by' do
    it 'returns nil when dn is not provided' do
      expect(described_class.find_or_create_by(uuid: 'some-uuid').errors).to_not be_empty
    end
  end
end
