class OCSPResponse
  extend Forwardable

  attr_reader :response

  def initialize(ocsp_request, response)
    @ocsp_request = ocsp_request
    @response = response
    @revoked = nil
  end

  def_delegators :@ocsp_request, :subject, :request, :authority

  def successful?
    response&.status&.zero?
  end

  def revoked?
    return @revoked unless @revoked.nil?

    @revoked = calculate_revocation
    log_if_interesting
    cache_revocation
    @revoked
  end

  def calculate_revocation
    return CertificateAuthority.revoked?(subject) unless successful? && verified? && valid_nonce?

    any_revoked? || false
  end

  def verified?
    cert_store = CertificateStore.instance

    chain = cert_store.x509_certificate_chain(subject).map(&:x509_cert)

    # If the cert is in the store, we trust it, so that's sufficient.
    # This will spit out a warning if the response is not signed by
    # the cert we expect since we won't have the unexpected signing
    # cert in the chain. That's okay.
    response&.basic&.verify(chain, cert_store.store, OpenSSL::OCSP::TRUSTOTHER)
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
  #
  # Entrust caches their OCSP responses, so we can't expect a nonce in their responses.
  #
  def valid_nonce?
    !request.check_nonce(response.basic).zero?
  end

  def any_revoked?
    return unless response
    expected_serial = subject.serial
    response.basic.status.any? do |status|
      status[0].serial == expected_serial &&
        status[1] == OpenSSL::OCSP::V_CERTSTATUS_REVOKED
    end
  end

  def logging_filename
    'OCSP:' + subject.logging_filename
  end

  def logging_content
    if response
      [subject.to_pem, to_pem, to_text].join("\n")
    else
      'No Response'
    end
  end

  def to_pem
    "----- BEGIN OCSP -----\n" +
      Base64.encode64(response.to_der) +
      "----- END OCSP -----\n"
  end

  def to_text
    general_text_description +
      "Basic Response:\n  Responses:\n" +
      response.basic.status.map { |status| status_description(status) }.join('')
  end

  def log_if_interesting
    return if successful? && !revoked?
    CertificateLoggerService.log_ocsp_response(self)
  end

  def cache_revocation
    return unless revoked?
    # save serial number as revoked
    authority&.certificate_revocations&.create(serial: subject.serial)
  end

  private

  def general_text_description
    "Subject Serial: #{subject.serial}\n" \
      "Status String: #{response.status_string}\n" \
      "Status Int: #{response.status}\n"
  end

  STATUS_STRINGS = {
    OpenSSL::OCSP::V_CERTSTATUS_REVOKED => 'revoked',
    OpenSSL::OCSP::V_CERTSTATUS_GOOD => 'good',
    OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN => 'unknown',
  }.freeze

  # :reek:UtilityFunction
  def status_description(status)
    (certid, status_code, reason_code) = status
    reason_code = status_code == OpenSSL::OCSP::V_CERTSTATUS_REVOKED ? reason_code : '-'
    "    - Status Int: #{status_code}\n" \
      "      Status String: #{STATUS_STRINGS[status_code] || 'other'}\n" \
      "      Reason Int: #{reason_code}\n" \
      "      Cert Id:\n" \
      "        Serial: #{certid.serial}\n"
  end
end
