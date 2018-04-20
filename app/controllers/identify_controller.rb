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
      render plain: 'Invalid request', status: :bad_request
    end
  end

  private

  # :reek:UtilityFunction
  def token_for_referrer
    cert_pem = request.headers[CERT_HEADER]
    token = if cert_pem
              process_cert(CGI.unescape(cert_pem))
            else
              TokenService.box(error: 'certificate.none')
            end
    CGI.escape(token)
  end

  # :reek:UtilityFunction
  def process_cert(raw_cert)
    cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))

    cert.token
  rescue OpenSSL::X509::CertificateError
    TokenService.box(error: 'certificate.bad')
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
