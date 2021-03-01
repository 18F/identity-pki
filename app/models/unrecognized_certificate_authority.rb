class UnrecognizedCertificateAuthority < ApplicationRecord
  validates :key, presence: true, uniqueness: true, case_sensitive: false,
                  format: { with: /\A(\h{2})(:\h{2})+\Z/ }
  validates :dn, presence: true

  def self.find_or_create_for_certificate(certificate)
    return if certificate.issuer.blank?

    create_with(
      certificate.issuer_metadata
    ).find_or_create_by(key: certificate.signing_key_id)
  end
end
