class CertificateRevocation < ApplicationRecord
  validates :serial, presence: true, case_sensitive: false,
                     uniqueness: { scope: :certificate_authority_id },
                     format: { with: /\A\d+\Z/, message: 'must be a positive integer' }
  validates :certificate_authority, presence: true

  belongs_to :certificate_authority
end
