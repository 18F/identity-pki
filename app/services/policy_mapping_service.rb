class PolicyMappingService
  def initialize(certificate)
    @certificate = certificate
  end

  def call
    policy_mapping
  end

  private

  attr_reader :certificate

  def chain(set = [])
    # walk from the cert to a root - we can do this safely because we've already
    # constructed a path from the leaf cert to a trusted root elsewhere
    store = CertificateStore.instance
    @chain ||= begin
      signer = store[certificate.signing_key_id]
      while signer
        set << signer
        signer = !signer.self_signed? && store[signer.signing_key_id]
      end
      set.reverse
    end
  end

  # :reek:UtilityFunction
  def new_mapping
    Hash.new { |_, key| key }
  end

  # ultimately maps OIDs seen in child certs to OIDs we expect at the top level
  def policy_mapping
    return new_mapping if chain.empty?
    allowed_depth = CertificatePolicies.new(chain.first).policy_mappings_allowed

    chain.each_with_object(new_mapping) do |cert, mapping|
      next if allowed_depth != :any && allowed_depth.negative?

      allowed_depth = import_mapping(mapping, cert, allowed_depth)
    end
  end

  # :reek:UtilityFunction
  def import_mapping(mapping, cert, allowed_depth)
    policy = CertificatePolicies.new(cert)

    policy.policy_mappings.each do |(key, value)|
      # RFC 5280, section 4.2.1.5 requires that no mapping can be to or from
      # the value anyPolicy.
      next if ([key, value] & ['X509v3 Any Policy', Certificate::ANY_POLICY]).any?
      mapping[key] = mapping[value]
    end
    policy.policy_mappings_allowed(allowed_depth)
  end
end
