class Certificate
  extend Forwardable

  def initialize(x509_cert)
    @x509_cert = x509_cert
  end

  def_delegators :@x509_cert, :not_before, :not_after, :subject, :issuer, :verify,
                 :public_key, :serial

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

  def valid?
    !expired? &&
      (trusted_root? || !self_signed? && !revoked? && signature_verified?)
  end

  def to_pem
    <<~PEM
      Subject: #{subject}
      Issuer: #{issuer}
      #{@x509_cert.to_pem}
    PEM
  end

  # :reek:UtilityFunction
  def signature_verified?
    signing_cert = CertificateStore.instance[signing_key_id]
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

  def token(extra)
    if valid?
      token_for_valid_certificate(extra)
    else
      token_for_invalid_certificate(extra)
    end
  end

  # :reek:UtilityFunction
  def get_extension(oid)
    extension = @x509_cert.extensions.detect { |record| record.oid == oid }
    extension&.value
  end

  private

  # :reek:UtilityFunction
  def token_for_valid_certificate(extra)
    subject_s = subject.to_s(OpenSSL::X509::Name::RFC2253)
    piv = PivCac.find_or_create_by(dn: subject_s)
    TokenService.box(
      extra.merge(
        subject: subject_s,
        uuid: piv.uuid
      )
    )
  end

  # :reek:UtilityFunction
  def token_for_invalid_certificate(extra)
    # figure out the reason for being invalid
    reason = if !signature_verified?
               'unverified'
             elsif revoked?
               'revoked'
             elsif expired?
               'expired'
             else
               'invalid'
             end

    TokenService.box(extra.merge(error: "certificate.#{reason}"))
  end
end
