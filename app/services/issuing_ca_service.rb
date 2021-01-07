class IssuingCaService
  # TODO: Only allow downloading bundles from allowed domains
  # Do this for all of the stored certs
  CA_ISSUER_HOST_ALLOW_LIST = ['sspweb.managed.entrust.com']
  class UnexpectedPKCS7Response < StandardError; end

  CA_RESPONSE_CACHE_EXPIRATION = 60.minutes

  def self.fetch_signing_key_for_cert(cert)
    return nil unless cert.aia && cert.aia['CA Issuers'].is_a?(Array)
    ca_issuers = cert.aia['CA Issuers'].map do |issuer|
      issuer = issuer.to_s
      next unless issuer.starts_with?('URI')
      issuer = issuer.gsub(/^URI:/, '')
      uri = URI.parse(issuer)
      next unless uri.scheme == 'http'
      next unless allowed_host?(uri.host)
      uri
    end.compact

    ca_issuers.each do |ca_issuer_uri|
      signing_cert = fetch_issuing_certificate(ca_issuer_uri, cert.signing_key_id)
      return signing_cert if signing_cert.present?
    end

    nil
  end

  def self.fetch_issuing_certificate(ca_issuer_uri, signing_key_id)
    @ca_certificates_response_cache ||= MiniCache::Store.new
    key = [ca_issuer_uri.to_s, signing_key_id].inspect

    cached_result = @ca_certificates_response_cache.get(key)
    return cached_result if @ca_certificates_response_cache.set?(key)

    ca_x509_certificates = fetch_certificates(ca_issuer_uri)

    ca_x509_certificates.each do |ca_x509_certificate|
      ca_certificate = Certificate.new(ca_x509_certificate)
      if signing_key_id == ca_certificate.key_id
        return @ca_certificates_response_cache.set(key, ca_certificate, expires_in: CA_RESPONSE_CACHE_EXPIRATION)
      end
    end

    @ca_certificates_response_cache.set(key, nil, expires_in: CA_RESPONSE_CACHE_EXPIRATION)
  end

  def self.fetch_certificates(issuer_uri)
    http = Net::HTTP.new(issuer_uri.hostname, issuer_uri.port)
    response = http.get(issuer_uri.path)
    if response.kind_of?(Net::HTTPSuccess)
      OpenSSL::PKCS7.new(response.body).certificates
    else
      handle_exception(UnexpectedPKCS7Response.new(response.body))
      []
    end
  rescue OpenSSL::PKCS7::PKCS7Error, ArgumentError => e
    handle_exception(e)
    []
  end

  def self.allowed_host?(host)
    return true if CA_ISSUER_HOST_ALLOW_LIST.include?(host)

    Rails.logger.info("CA Issuer Host Not Allowed: #{host}")
    false
  end

  def self.handle_exception(exception)
    NewRelic::Agent.notice_error(exception)
  end
end
