require 'net/http'
require 'openssl'

class CertificateRevocationListService
  NO_CRL_URL_ERROR = 'No CRL URL'.freeze

  # TODO: validate signature of CRL file (LG-202)
  def self.retrieve_serials_from_url(crl_http_url)
    raise NO_CRL_URL_ERROR unless crl_http_url

    raw = Net::HTTP.get(URI(crl_http_url))

    crl_store = OpenSSL::X509::CRL.new(raw)
    crl_store.revoked.map(&:serial).map(&:to_s)
  end
end
