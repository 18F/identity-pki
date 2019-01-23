class Certificate
  extend Forwardable

  attr_accessor :x509_cert

  REVOCATION_CACHE_EXPIRATION = 5.minutes
  ANY_POLICY = '2.5.29.32.0'.freeze

  def initialize(x509_cert)
    @x509_cert = x509_cert
    @cert_policies = CertificatePolicies.new(self)
  end

  def_delegators :x509_cert, :not_before, :not_after, :subject, :issuer, :verify,
                 :public_key, :serial, :to_text

  def_delegators :@cert_policies, :allowed_by_policy?, :critical_policies_recognized?

  def trusted_root?
    CertificateStore.trusted_ca_root_identifiers.include?(key_id)
  end

  def revoked?
    Certificate.revocation_status?(self) { calculate_revocation_status }
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def calculate_revocation_status
    ocsp_response = OCSPService.new(self).call
    if !ocsp_response.successful?
      CertificateLoggerService.log_ocsp_response(ocsp_response)
      CertificateAuthority.revoked?(self)
    elsif ocsp_response.revoked?
      CertificateLoggerService.log_ocsp_response(ocsp_response)
      # save serial number as revoked
      # temporarily not caching it while we investigate some reported wrong revocations via OCSP
      # ocsp_response.authority&.certificate_revocations&.create!(serial: serial) if revoked_status
      true
    else
      false
    end
  end

  def self.revocation_status?(certificate, &block)
    @revocation_cache ||= MiniCache::Store.new
    key = [certificate.issuer, certificate.subject, certificate.serial].map(&:to_s).inspect
    @revocation_cache.get_or_set(key, expires_in: REVOCATION_CACHE_EXPIRATION, &block)
  end

  def self.clear_revocation_cache
    @revocation_cache = nil
  end

  def ==(other)
    subject == other.subject &&
      serial == other.serial &&
      signing_key_id == other.signing_key_id
  end

  def expired?
    now = Time.zone.now
    not_before > now || now > not_after # expiration bounds
  end

  def self_signed?
    signing_key_id == key_id
  end

  def validate_cert
    if expired?
      'expired'
    elsif trusted_root?
      # The other checks are all irrelevant if we trust the root.
      'valid'
    else
      validate_untrusted_root
    end
  end

  def validate_untrusted_root
    if self_signed?
      'self-signed cert'
    elsif !signature_verified?
      'unverified'
    elsif revoked?
      'revoked'
    else
      'valid'
    end
  end

  def valid?
    validate_cert == 'valid'
  end

  def to_pem
    "Subject: #{subject}\nIssuer: #{issuer}\n#{@x509_cert.to_pem}"
  end

  # :reek:UtilityFunction
  def signature_verified?
    signing_cert = CertificateStore.instance[signing_key_id]
    UnrecognizedCertificateAuthority.find_or_create_for_certificate(self) unless signing_cert
    signing_cert && verify(signing_cert.public_key) && signing_cert.valid?
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

  def crl_http_url
    extract_http_url(get_extension('crlDistributionPoints')&.split(/\s*\n\s*/))
  end

  def aia
    @aia ||= get_extension('authorityInfoAccess')&.
      split(/\n/)&.
      map { |line| line.split(/\s*-\s*/, 2) }&.
      each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(key, value), memo|
        memo[key] << value
      end
  end

  def token(extra)
    maybe_log_certificate
    if valid?
      token_for_valid_certificate(extra)
    else
      token_for_invalid_certificate(extra)
    end
  end

  def ca_issuer_http_url
    extract_http_url(aia['CA Issuers']) if aia.present?
  end

  def ocsp_http_url
    extract_http_url(aia['OCSP']) if aia.present?
  end

  def issuer_metadata
    {
      dn: issuer,
      crl_http_url: crl_http_url,
      ca_issuer_url: ca_issuer_http_url,
      ocsp_url: ocsp_http_url,
    }
  end

  def logging_filename
    [key_id, signing_key_id, serial].join('::')
  end

  def logging_content
    to_text + "\n\n" + to_pem
  end

  private

  def maybe_log_certificate
    return if valid? && critical_policies_recognized? && allowed_by_policy?
    CertificateLoggerService.log_certificate(self)
  end

  # :reek:UtilityFunction
  def get_extension(oid)
    @x509_cert.extensions.detect { |record| record.oid == oid }&.value
  end

  # :reek:UtilityFunction
  def extract_http_url(list)
    list&.detect { |line| line.start_with?('URI:http') }&.sub(/^URI:/, '')
  end

  # :reek:UtilityFunction
  def token_for_valid_certificate(extra)
    subject_s = subject.to_s(OpenSSL::X509::Name::RFC2253)
    piv = PivCac.find_or_create_by(dn: subject_s)
    Rails.logger.info('Returning a token for a valid certificate.')
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
    reason = validate_cert

    Rails.logger.warn("Certificate invalid: #{reason}")
    TokenService.box(extra.merge(error: "certificate.#{reason}"))
  end
end
