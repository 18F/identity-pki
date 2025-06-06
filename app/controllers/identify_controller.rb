require 'cgi'
require 'open3'

class IdentifyController < ApplicationController
  TOKEN_LIFESPAN = 5.minutes
  CERT_HEADER = 'X-Client-Cert'.freeze
  REFERER_HEADER = 'Referer'.freeze

  delegate :logger, to: Rails

  rescue_from URI::InvalidURIError, with: :render_bad_referrer_error
  rescue_from ActionController::ParameterMissing, with: :render_missing_param_error

  def create
    if referrer
      # given a valid certificate from the client, return a token
      referrer.query = "token=#{token_for_referrer}"

      # redirect to referer OR redirect to a preconfigured URL template
      # this is safe because we validate that it is an allowed referrer
      redirect_to referrer.to_s, allow_other_host: true
    else
      render_bad_request('No referrer')
    end
  end

  private

  def render_bad_request(reason)
    logger.warn("#{reason}, returning Bad Request.")
    render plain: 'Invalid request', status: :bad_request
  end

  def render_bad_referrer_error
    render_bad_request('Bad referrer')
  end

  def render_missing_param_error(exception)
    render_bad_request("Missing #{exception.param} param")
  end

  def token_for_referrer
    cert_pem = client_cert
    token = if cert_pem
              process_cert(cert_pem)
            else
              certificate_none_error
            end
    CGI.escape(token)
  end

  def certificate_none_error
    logger.warn('No certificate found in headers.')
    TokenService.box(error: 'certificate.none', nonce: nonce)
  end

  def client_cert
    cert_pem = request.headers[CERT_HEADER] || request.headers.env['rack.peer_cert']
    return unless cert_pem
    if IdentityConfig.store.client_cert_escaped
      CGI.unescape(cert_pem)
    else
      cert_pem.delete("\t")
    end
  end

  def process_cert(raw_cert)
    cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))

    log_certificate(cert)

    cert.token(nonce: nonce)
  rescue OpenSSL::X509::CertificateError => error
    certificate_bad_error(error)
  end

  def certificate_bad_error(error)
    logger.warn("CertificateError: #{error.message}")
    TokenService.box(error: 'certificate.bad', nonce: nonce)
  end

  def nonce
    @nonce ||= params.require(:nonce)
  end

  def referrer
    @referrer ||= begin
      value = params[:redirect_uri] || request.headers[REFERER_HEADER]
      if value
        value = URI(value)
        value.query = ''
        value.fragment = ''
      end
      value if value && allowed_referrer?(value)
    end
  end

  def allowed_referrer?(uri)
    allowed_host = IdentityConfig.store.identity_idp_host
    !allowed_host || uri.host == allowed_host
  end

  def log_certificate(cert)
    validation_result = cert.validate_cert(is_leaf: true)
    valid = validation_result == 'valid'
    attributes = {
      name: 'Certificate Processed',
      signing_key_id: cert.signing_key_id,
      key_id: cert.key_id,
      certificate_chain_signing_key_ids: cert.x509_certificate_chain_key_ids,
      issuer: cert.issuer.to_s,
      valid_policies: cert.valid_policies?,
      mapped_policy_oids: cert.mapped_policies.map { |oid| [oid, true] }.to_h,
      valid: valid,
      error: !valid ? validation_result : nil,
    }

    attributes.delete(:issuer) if validation_result == 'self-signed cert'
    if valid
      attributes[:matched_policy_oids] = cert.matched_policy_oids.map { |oid| [oid, true] }.to_h
    end

    logger.info(attributes.to_json)
  end
end
