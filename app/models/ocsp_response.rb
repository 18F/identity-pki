class OCSPResponse
  extend Forwardable

  attr_reader :response

  def initialize(ocsp_request, response)
    @ocsp_request = ocsp_request
    @response = response
  end

  def_delegators :@ocsp_request, :subject, :request, :authority

  def revoked?
    return unless verified? && valid_nonce?
    any_revoked?
  end

  def verified?
    cert_store = CertificateStore.instance

    chain = cert_store.x509_certificate_chain(subject).map(&:x509_cert)

    # If the cert is in the store, we trust it, so that's sufficient.
    # This will spit out a warning if the response is not signed by
    # the cert we expect since we won't have the unexpected signing
    # cert in the chain. That's okay.
    response.verify(chain, cert_store.store, OpenSSL::OCSP::TRUSTOTHER)
  end

  def valid_nonce?
    !request.check_nonce(response).zero?
  end

  # -1 == nonce in request only
  #  0 == nonces both present and not equal
  #  1 == nonces present and equal
  #  2 == nonces both absent
  #  3 == nonce present in response only
  #
  # 2 and 3 can't happen since we set it in the request; 0 is always an error
  # whether or not we accept -1 depends on if we expect all OCSP responders
  # to echo back our nonce. We'll be forgiving for now.
  def any_revoked?
    response.status.any? { |status| status[1] == OpenSSL::OCSP::V_CERTSTATUS_REVOKED }
  end
end
