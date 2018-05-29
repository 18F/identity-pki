require 'rails_helper'

RSpec.describe UnrecognizedCertificateAuthority, type: :model do
  let(:authority) { create(:unrecognized_certificate_authority) }

  subject { authority }
  it { is_expected.to validate_uniqueness_of(:key) }
  it { is_expected.to validate_presence_of(:dn) }
end
