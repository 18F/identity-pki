class HealthChecker
  Result = Struct.new(:healthy, :info, keyword_init: true) do
    alias_method :healthy?, :healthy
  end

  def initialize(certificates_store: CertificateStore.instance)
    @certificates_store = certificates_store
  end

  # @param [Time] deadline
  # @return [Result]
  def check_certs(deadline:)
    expiring_certs = certificates_store.select do |cert|
      cert.expired?(deadline)
    end

    Result.new(
      healthy: expiring_certs.empty?,
      info: {
        deadline: deadline,
        expiring: expiring_certs.sort_by(&:not_after).map { |cert| cert_info(cert) },
      }
    )
  end

  private

  attr_reader :certificates_store

  # @param [Certificate] cert
  def cert_info(cert)
    {
      expiration: cert.not_after,
      subject: cert.subject.to_s,
      issuer: cert.issuer.to_s,
      key_id: cert.key_id,
    }
  end
end
