class Certificate
  extend Forwardable

  def initialize(x509_cert)
    @x509_cert = x509_cert
  end

  def_delegators :@x509_cert, :not_before, :not_after, :subject, :verify, :public_key, :serial

  def trusted_root?
    CertificateStore.trusted_ca_root_identifiers.include?(key_id)
  end

  def revoked?
    CertificateAuthority.revoked?(signing_key_id, serial.to_s)
  end

  def expired?
    now = Time.zone.now
    not_before > now || now > not_after # expiration bounds
  end

  def self_signed?
    signing_key_id == key_id
  end

  def valid?(certificate_store)
    !expired? && (
      trusted_root? ||
      !self_signed? && !revoked? && signature_verified?(certificate_store)
    )
  end

  # :reek:UtilityFunction
  def signature_verified?(certificate_store)
    signing_cert = certificate_store[signing_key_id]
    signing_cert && verify(signing_cert.public_key)
  end

  def ca_capable?
    basic_constraints = get_extension('basicConstraints')&.split(/\s*,\s*/)
    key_usage = get_extension('keyUsage')&.split(/\s*,\s*/)
    basic_constraints&.include?('CA:TRUE') && key_usage&.include?('Certificate Sign')
  end

  def key_id
    get_extension('subjectKeyIdentifier')&.upcase
  end

  def signing_key_id
    get_extension('authorityKeyIdentifier')&.sub(/^keyid:/, '')&.chomp&.upcase
  end

  # :reek:UtilityFunction
  def get_extension(oid)
    extension = @x509_cert.extensions.detect { |record| record.oid == oid }
    extension&.value
  end
end
