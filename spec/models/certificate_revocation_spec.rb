require 'rails_helper'

RSpec.describe CertificateRevocation, type: :model do
  let(:revocation) { create(:certificate_revocation) }

  subject { revocation }

  it { is_expected.to validate_uniqueness_of(:serial).scoped_to(:certificate_id).case_insensitive }
  it { is_expected.to validate_presence_of(:certificate) }
end
