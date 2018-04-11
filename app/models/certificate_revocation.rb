class CertificateRevocation < ApplicationRecord
  validates :serial, presence: true, case_sensitive: false,
                     uniqueness: { scope: :certificate_id },
                     format: { with: /\A\d+\Z/, message: 'must be a positive integer' }
  validates :certificate, presence: true

  belongs_to :certificate
end
