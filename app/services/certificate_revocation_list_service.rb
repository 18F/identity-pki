require 'net/http'
require 'openssl'

class CertificateRevocationListService
  NO_CRL_URL_ERROR = 'No CRL URL'.freeze

  class << self
    def retrieve_serials_from_url(crl_http_url, key_id)
      raw = fetch_crl(crl_http_url)

      return [] if raw.blank?

      Rails.logger.info "  Received #{raw.size} bytes"
      retrieve_serials_from_crl(OpenSSL::X509::CRL.new(raw), key_id)
    end

    def retrieve_serials_from_crl(crl_store, key_id)
      return [] unless crl_store && valid_crl?(crl_store, CertificateStore.instance[key_id])

      crl_store.revoked.map(&:serial).map(&:to_s)
    end

    def valid_crl?(crl_store, certificate)
      certificate &&
        crl_store.issuer == certificate.subject &&
        crl_store.verify(certificate.public_key)
    end

    private

    def fetch_crl(url)
      raise NO_CRL_URL_ERROR if url.blank?

      response = get_response(url)

      case response
      when Net::HTTPSuccess then
        response.body
      else
        Rails.logger.warn "  unable to fetch <#{url}>: #{response.message}"
        nil
      end
    end

    def get_response(url)
      parsed_url = URI(url)
      http = Net::HTTP.new(parsed_url.hostname)
      http.get(parsed_url.path)
    end
  end
end
