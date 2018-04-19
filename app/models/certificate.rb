class Certificate < ApplicationRecord
  validates :key, presence: true, uniqueness: true, case_sensitive: false,
                  format: { with: /\A(\h{2})(:\h{2})+\Z/ }
  validates :dn, :valid_not_before, :valid_not_after, presence: true

  has_many :certificate_revocations, dependent: :destroy

  scope :with_crl_http_url, -> { where.not(crl_http_url: nil) }
  ##
  # Fetches the CRL from the stored URL and adds any new serial numbers.
  # Will raise on errors.
  #
  def update_revocations
    serials = CertificateRevocationListService.retrieve_serials_from_url(crl_http_url)
    already_revoked = certificate_revocations.pluck(:serial)
    (serials - already_revoked).each do |serial|
      certificate_revocations.create(serial: serial)
    end
  end
end
