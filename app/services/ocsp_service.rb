require 'net/http'
require 'openssl'
require 'uri'

class OcspService
  attr_reader :subject, :authority, :request

  OCSP_RESPONSE_CACHE_EXPIRATION = 5.minutes

  def initialize(subject)
    @subject = subject
    @authority = CertificateAuthority.find_by(key: subject.signing_key_id)
    @request = OpenSSL::OCSP::Request.new
    build_request if @authority&.certificate
  end

  def call
    return OpenStruct.new(revoked?: CertificateAuthority.revoked?(subject)) if no_request

    # we want to cache the call for a few minutes so we don't hammer on the same request
    OcspService.ocsp_response(ocsp_url_for_subject, authority.certificate, subject) do
      response = make_http_request(ocsp_url_for_subject, request.to_der)
      OcspResponse.new(self, response)
    end
  end

  def self.ocsp_response(url, issuer, subject, &block)
    @ocsp_response_cache ||= MiniCache::Store.new
    key = [issuer.subject, subject.subject, subject.serial, url].map(&:to_s).inspect
    @ocsp_response_cache.get_or_set(key, expires_in: OCSP_RESPONSE_CACHE_EXPIRATION, &block)
  end

  def self.clear_ocsp_response_cache
    @ocsp_response_cache = nil
  end

  private

  def no_request
    !@authority&.certificate || request.blank?
  end

  def certificate_id
    @certificate_id ||= begin
      issuer = authority.certificate
      digest = OpenSSL::Digest.new('SHA1')
      OpenSSL::OCSP::CertificateId.new(subject.x509_cert, issuer.x509_cert, digest)
    end
  end

  def build_request
    request.add_certid(certificate_id)
    request.add_nonce
  end

  def ocsp_url_for_subject
    authority.ocsp_http_url.presence || begin
      uri = subject.ocsp_http_url
      authority.ocsp_http_url = uri
      authority.save!
      uri
    end
  end

  def make_http_request(uri, request, limit = 10)
    return if limit.negative? || uri.blank? || request.blank?

    handle_response(make_single_http_request(URI(uri), request), limit)
  rescue SocketError
    nil # we simply have nothing if we can't connect
  end

  def handle_response(response, limit)
    case response
    when Net::HTTPSuccess then
      process_http_response_body(response.body)
    when Net::HTTPRedirection then
      make_http_request(response['location'], request, limit - 1)
    end
  end

  def make_single_http_request(uri, request, retries = 0)
    make_single_http_request!(uri, request)
  rescue Errno::ECONNRESET, Timeout::Error => e
    retries -= 1
    if retries.negative?
      log_ocsp_error(:ocsp_timeout, e)
      return
    end
    sleep(1)
    retry
  end

  def make_single_http_request!(uri, request)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.open_timeout = IdentityConfig.store.http_open_timeout
    http.read_timeout = IdentityConfig.store.http_read_timeout
    http.post(uri.path.presence || '/', request, 'content-type' => 'application/ocsp-request')
  end

  def process_http_response_body(body)
    OpenSSL::OCSP::Response.new(body) if body.present?
  rescue OpenSSL::OCSP::OCSPError => e
    log_ocsp_error(:ocsp_response_error, e)
    nil
  end

  def log_ocsp_error(error_type, exception)
    info = {
      error_type: error_type,
      ocsp_url_for_subject: ocsp_url_for_subject,
      key_id: subject.key_id,
    }
    Rails.logger.warn("OCSP error: #{info.to_json}")
  end
end
