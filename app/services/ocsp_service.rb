require 'net/http'
require 'openssl'
require 'uri'

class OCSPService
  attr_reader :subject, :authority, :request

  NO_AUTHORITY_RESPONSE = OpenStruct.new(revoked?: nil).freeze

  def initialize(subject)
    @subject = subject
    @authority = CertificateAuthority.find_by(key: subject.signing_key_id)
    @request = OpenSSL::OCSP::Request.new
    build_request if @authority&.certificate
  end

  def call
    return NO_AUTHORITY_RESPONSE unless @authority&.certificate && request.present?
    response = make_http_request(ocsp_url_for_subject, request.to_der)
    OCSPResponse.new(self, response)
  end

  private

  def build_request
    issuer = authority.certificate
    digest = OpenSSL::Digest::SHA1.new
    certificate_id = OpenSSL::OCSP::CertificateId.new(subject.x509_cert, issuer.x509_cert, digest)
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

  def make_single_http_request(uri, request, retries = 3)
    make_single_http_request!(uri, request)
  rescue Errno::ECONNRESET
    retries -= 1
    return if retries.negative?
    sleep(1)
    retry
  end

  # :reek:UtilityFunction
  def make_single_http_request!(uri, request)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.post(uri.path.presence || '/', request, 'content-type' => 'application/ocsp-request')
  end

  # :reek:UtilityFunction
  def process_http_response_body(body)
    OpenSSL::OCSP::Response.new(body) if body.present?
  end
end
