class CertificatePolicies
  KNOWN_POLICIES = [
    # Policies we've seen marked critical
    'basicConstraints',
    'inhibitAnyPolicy',
    'keyUsage',
    'policyConstraints',
    # Policies we use that could be marked critical
    'authorityInfoAccess',
    'authorityKeyIdentifier',
    'certificatePolicies',
    'crlDistributionPoints',
    'policyMappings',
    'subjectKeyIdentifier',
    # Policies we don't use
    'nameConstraints',
    'subjectAltName',
    'subjectInfoAccess',
  ].freeze

  def initialize(cert)
    @certificate = cert
  end

  def allowed_by_policy?
    # if at least one policy in the cert matches one of the "required policies", then we're good
    # otherwise, we want to allow it for now, but log the cert so we can see what policies are
    # coming up
    # This policy check is only on the leaf certificate - not used by CAs
    mapping = PolicyMappingService.new(@certificate).call
    expected_policies = required_policies
    cert_policies = policies.map { |policy| mapping[policy] }
    (cert_policies & expected_policies).any?
  end

  def policies
    (get_extension('certificatePolicies') || '').split(/\n/).map do |line|
      line.sub(/^Policy:\s+/, '')
    end
  end

  def critical_policies_recognized?
    (certificate.x509_cert.extensions.select(&:critical?).map(&:oid) - KNOWN_POLICIES).empty?
  end

  # provides a mapping of policy OIDs seen in child certificates to policy OIDs expected by the
  # issuing certificate
  def policy_mappings
    get_extension('policyMappings')&.
    split(/\s*,\s*/)&.
    map { |mapping| mapping.split(/:/).reverse }.
      to_h
  end

  ANY_POLICY_MAPPING_DEPTH = InfinitePolicyMappingDepth.new

  def policy_mappings_allowed(previous_allowed = ANY_POLICY_MAPPING_DEPTH)
    [inhibit_policy_mapping, previous_allowed - 1].min
  end

  def policy_constraints
    get_extension('policyConstraints')&.
    split(/\s*,\s*/)&.
    map { |mapping| mapping.split(/:/) }.
      to_h
  end

  def inhibit_policy_mapping
    value = policy_constraints.fetch('Inhibit Policy Mapping') { :any }
    if value == :any
      ANY_POLICY_MAPPING_DEPTH
    else
      FinitePolicyMappingDepth.new(value)
    end
  end

  private

  attr_reader :certificate

  def get_extension(oid)
    certificate.x509_cert.extensions.detect { |record| record.oid == oid }&.value
  end

  def required_policies
    JSON.parse(Figaro.env.required_policies || '[]')
  end
end
