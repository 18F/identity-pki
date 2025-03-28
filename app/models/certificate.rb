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

  def_delegators :@cert_policies, :allowed_by_policy?, :critical_policies_recognized?, :matched_policy_oids

  def trusted_root?
    CertificateStore.trusted_ca_root_identifiers.include?(key_id)
  end

  def revoked?
    Certificate.revocation_status?(self) { OcspService.new(self).call.revoked? }
  end

  def mapped_policies
    @cert_policies.mapped_policies
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

  def expired?(now = Time.zone.now)
    not_before > now || now > not_after # expiration bounds
  end

  def self_signed?
    signing_key_id == key_id
  end

  def validate_cert(is_leaf: false)
    if expired?
      'expired'
    elsif trusted_root? && !is_leaf
      # The other checks are all irrelevant if we trust the root.
      raise "trusted root missing from store #{key_id}" if CertificateStore.instance[key_id].blank?
      'valid'
    else
      validate_untrusted_root(is_leaf: is_leaf)
    end
  end

  def validate_untrusted_root(is_leaf:)
    if self_signed?
      'self-signed cert'
    elsif !signature_verified?
      'unverified'
    elsif revoked?
      'revoked'
    elsif is_leaf && !signing_key_in_store? && !valid_policies?
      'bad policy'
    else
      'valid'
    end
  end

  def valid?(is_leaf: false)
    validate_cert(is_leaf: is_leaf) == 'valid'
  end

  def pem_filename(suffix: nil)
    "#{subject.to_s(OpenSSL::X509::Name::COMPAT)}#{suffix}.pem"
  end

  def to_pem
    "Subject: #{subject}\nIssuer: #{issuer}\n#{@x509_cert.to_pem}"
  end

  def signature_verified?
    # Use HTTP stuff to download PKCS7 bundles
    signing_cert = CertificateStore.instance[signing_key_id] ||
                   IssuingCaService.fetch_signing_key_for_cert(self)
    UnrecognizedCertificateAuthority.find_or_create_for_certificate(self) unless signing_cert
    signing_cert && verify(signing_cert.public_key) && signing_cert.valid?
  end

  def signing_key_in_store?
    CertificateStore.instance[signing_key_id].present?
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
    get_extension('authorityKeyIdentifier')&.lines&.first
                                           &.sub(/\Akeyid:/, '')&.chomp&.upcase
  end

  def crl_http_url
    extract_http_url(get_extension('crlDistributionPoints')&.split(/\s*\n\s*/))
  end

  def aia
    @aia ||= parse_extension_to_hash(get_extension('authorityInfoAccess')) || {}
  end

  def subject_info_access
    @subject_info_access ||= parse_extension_to_hash(get_extension('subjectInfoAccess')) || {}
  end

  def token(extra)
    if valid?(is_leaf: true)
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

  def valid_policies?
    critical_policies_recognized? && allowed_by_policy?
  end

  def sha1_fingerprint
    OpenSSL::Digest::SHA1.new(x509_cert.to_der).to_s
  end

  def x509_certificate_chain_key_ids
    cert_store.x509_certificate_chain(self).map(&:key_id)
  end

  private

  def get_extension(oid)
    @x509_cert.extensions.detect { |record| record.oid == oid }&.value
  end

  def extract_http_url(list)
    list&.detect { |line| line.start_with?('URI:http') }&.sub(/^URI:/, '')
  end

  def token_for_valid_certificate(extra)
    # Log the certificate if it is valid, but we would reject it for policy
    # failures without the intermediate certs in the store
    CertificateLoggerService.log_certificate(self) if !valid_policies?

    subject_s = subject.to_s(OpenSSL::X509::Name::RFC2253)
    piv = PivCac.find_or_create_by(dn: subject_s)
    Rails.logger.info('Returning a token for a valid certificate.')
    TokenService.box(
      extra.merge(
        subject: subject_s,
        issuer: issuer.to_s,
        uuid: piv.uuid,
        key_id: key_id,
      )
    )
  end

  def cert_store
    CertificateStore.instance
  end

  def token_for_invalid_certificate(extra)
    CertificateLoggerService.log_certificate(self)

    # figure out the reason for being invalid
    reason = validate_cert(is_leaf: true)

    Rails.logger.warn("Certificate invalid: #{reason}")
    TokenService.box(extra.merge(error: "certificate.#{reason}", key_id: key_id))
  end

  def parse_extension_to_hash(extension)
    return nil if extension.blank?

    extension.split(/\n/)&.
      map { |line| line.split(/\s*-\s*/, 2) }&.
      each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(key, value), memo|
      memo[key] << value
    end
  end
end
