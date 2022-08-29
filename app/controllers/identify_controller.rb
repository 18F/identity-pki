require 'cgi'
require 'openssl'
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
      redirect_to referrer.to_s
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
    login_certs_openssl_result = openssl_validate(cert.to_pem, Rails.root.join(IdentityConfig.store.login_certificate_bundle_file).to_s)
    ficam_certs_openssl_result = openssl_validate(cert.to_pem, Rails.root.join(IdentityConfig.store.ficam_certificate_bundle_file).to_s)
    attributes = {
      name: 'Certificate Processed',
      signing_key_id: cert.signing_key_id,
      key_id: cert.key_id,
      certificate_chain_signing_key_ids: cert.x509_certificate_chain_key_ids,
      issuer: cert.issuer.to_s,
      card_type: cert.card_type,
      valid_policies: cert.valid_policies?,
      valid: valid,
      error: !valid ? validation_result : nil,
      openssl_valid: login_certs_openssl_result[:valid],
      openssl_errors: login_certs_openssl_result[:errors],
      ficam_openssl_valid: ficam_certs_openssl_result[:valid],
      ficam_openssl_errors: ficam_certs_openssl_result[:errors],
    }

    attributes.delete(:issuer) if validation_result == 'self-signed cert'

    # Log certificate if it fails either OpenSSL validation, but passes our current validation or vice versa
    if valid != login_certs_openssl_result[:valid] || valid != ficam_certs_openssl_result[:valid]
      CertificateLoggerService.log_certificate(cert)
    end

    logger.info(attributes.to_json)
  end

  def openssl_validate(certificate_pem, certificate_bundle_file_path)
    return {} if !IdentityConfig.store.openssl_verify_enabled
    stdout, stderr, status = Open3.capture3('openssl', 'verify', '-purpose', 'sslclient', '-inhibit_any', '-explicit_policy', '-CAfile', certificate_bundle_file_path, '-policy_check', '-policy', '2.16.840.1.101.3.2.1.3.7', '-policy', '2.16.840.1.101.3.2.1.3.13', '-policy', '2.16.840.1.101.3.2.1.3.15', '-policy', '2.16.840.1.101.3.2.1.3.16', '-policy', '2.16.840.1.101.3.2.1.3.18', '-policy', '2.16.840.1.101.3.2.1.3.41', stdin_data: certificate_pem)

    stderr.strip!
    stdout.strip!
    errors = stderr.scan(/(error \d+ [\w :]+)$\n?/).flatten
    {
      valid: status.success? && stdout.ends_with?('OK') && errors.empty?,
      errors: errors.join(', '),
    }
  end
end
