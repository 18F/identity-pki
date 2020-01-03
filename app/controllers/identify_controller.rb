require 'cgi'
require 'openssl'

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

  # :reek:UtilityFunction
  def token_for_referrer
    cert_pem = client_cert
    token = if cert_pem
              process_cert(cert_pem)
            else
              logger.warn('No certificate found in headers.')
              TokenService.box(error: 'certificate.none', nonce: nonce)
            end
    CGI.escape(token)
  end

  def client_cert
    cert_pem = request.headers[CERT_HEADER] || request.headers.env['rack.peer_cert']
    return unless cert_pem
    if Figaro.env.client_cert_escaped == 'true'
      CGI.unescape(cert_pem)
    else
      cert_pem.delete("\t")
    end
  end

  # :reek:UtilityFunction
  def process_cert(raw_cert)
    cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))

    cert.token(nonce: nonce)
  rescue OpenSSL::X509::CertificateError => error
    logger.warn("CertificateError: #{error.message}")
    TokenService.box(error: 'certificate.bad', nonce: nonce)
  end

  def nonce
    @nonce ||= params.require(:nonce)
  end

  def referrer
    @referrer ||= begin
      value = request.headers[REFERER_HEADER]
      if value
        value = URI(value)
        value.query = ''
        value.fragment = ''
      end
      value if value && allowed_referrer?(value)
    end
  end

  # :reek:UtilityFunction
  def allowed_referrer?(uri)
    allowed_host = Figaro.env.identity_idp_host
    !allowed_host || uri.host == allowed_host
  end
end
