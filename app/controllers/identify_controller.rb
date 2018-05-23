require 'cgi'
require 'openssl'

class IdentifyController < ApplicationController
  TOKEN_LIFESPAN = 5.minutes
  CERT_HEADER = 'X-Client-Cert'.freeze
  REFERER_HEADER = 'Referer'.freeze

  def create
    if referrer
      # given a valid certificate from the client, return a token
      referrer.query = "token=#{token_for_referrer}"

      # redirect to referer OR redirect to a preconfigured URL template
      redirect_to referrer.to_s
    else
      Rails.logger.warn('No referrer, returning Bad Request.')
      render plain: 'Invalid request', status: :bad_request
    end
  end

  private

  # :reek:UtilityFunction
  def token_for_referrer
    cert_pem = client_cert
    token = if cert_pem
              process_cert(cert_pem)
            else
              Rails.logger.warn('No certificate found in headers.')
              TokenService.box(error: 'certificate.none', nonce: nonce)
            end
    CGI.escape(token)
  end

  def client_cert
    cert_pem = request.headers[CERT_HEADER]
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
    Rails.logger.warn("CertificateError: #{error.message}")
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
        # TODO: LG-183 - make sure referrer is whitelisted
      end
      value
    end
  end
end
