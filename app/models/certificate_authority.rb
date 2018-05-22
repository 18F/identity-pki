class CertificateAuthority < ApplicationRecord
  validates :key, presence: true, uniqueness: true, case_sensitive: false,
                  format: { with: /\A(\h{2})(:\h{2})+\Z/ }
  validates :dn, :valid_not_before, :valid_not_after, presence: true

  has_many :certificate_revocations, dependent: :destroy

  scope :with_crl_http_url, -> { where.not(crl_http_url: nil) }

  def self.find_or_create_for_certificate(certificate)
    key_id = certificate.key_id
    return unless key_id

    create_with(
      dn: certificate.subject,
      valid_not_before: certificate.not_before,
      valid_not_after: certificate.not_after
    ).find_or_create_by(key: key_id)
  end

  ##
  # Fetches the CRL from the stored URL and adds any new serial numbers.
  # Will raise on errors.
  #
  def update_revocations
    serials = CertificateRevocationListService.retrieve_serials_from_url(crl_http_url, key)

    revocations = new_revocations(serials)
    Rails.logger.info "  Adding #{revocations.size} revocations"
    CertificateRevocation.import(revocations,
                                 batch_size: 5000,
                                 validate: false,
                                 on_duplicate_key: :ignore)
  end

  def revoked?(serial)
    certificate_revocations.where(serial: serial).any?
  end

  def self.revoked?(key_id, serial)
    cert = find_by(key: key_id)
    # Cert should exist and not be revoked.
    cert&.revoked?(serial)
  end

  private

  def new_revocations(serials)
    already_revoked = certificate_revocations.pluck(:serial)
    self_id = id
    (serials - already_revoked).map do |serial|
      { serial: serial, certificate_authority_id: self_id }
    end
  end
end
