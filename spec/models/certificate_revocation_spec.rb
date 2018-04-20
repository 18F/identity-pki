require 'rails_helper'

RSpec.describe CertificateRevocation, type: :model do
  let(:revocation) { create(:certificate_revocation) }

  subject { revocation }

  it do
    is_expected.to(
      validate_uniqueness_of(:serial).
      scoped_to(:certificate_authority_id).
      case_insensitive
    )
  end

  it { is_expected.to validate_presence_of(:certificate_authority) }
end
