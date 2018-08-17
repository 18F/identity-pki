require 'openssl'
require 'rgl/dijkstra'
require 'rgl/adjacency'

# :reek:TooManyMethods
class CertificateStore
  include Singleton

  END_CERTIFICATE = "\n-----END CERTIFICATE-----\n".freeze

  extend Forwardable

  def initialize
    @certificates = {}
    @graph = RGL::DirectedAdjacencyGraph.new
  end

  def reset
    @certificates = {}
    @graph = RGL::DirectedAdjacencyGraph.new
  end

  def self.reset
    instance.reset
  end

  def_delegators :@certificates, :[], :count, :empty?, :map
  def_delegators :certificates, :each, :select
  def_delegators CertificateStore, :trusted_ca_root_identifiers, :clear_trusted_ca_root_identifiers

  def add_pem_file(filename)
    extract_certs(IO.binread(filename)).each(&method(:add_certificate))
  end

  def add_link(from, to)
    @graph.add_vertex(from) if from
    @graph.add_vertex(to) if to
    @graph.add_edge(from, to) if from && to
  end

  # :reek:FeatureEnvy
  def store
    OpenSSL::X509::Store.new.tap do |obj|
      obj.purpose = OpenSSL::X509::PURPOSE_ANY
      each { |cert| obj.add_cert(cert.x509_cert) }
    end
  end

  def certificates
    @certificates.values
  end

  def add_certificate(cert)
    key_id = cert&.key_id
    return unless key_id

    CertificateAuthority.find_or_create_for_certificate(cert)

    @certificates[key_id] = cert
    add_link(key_id, cert.signing_key_id)
  end

  def x509_certificate_chain(cert)
    trusted_ca_root_identifiers.each do |cert_root_id|
      sequence = x509_certificate_chain_to_root(cert, cert_root_id)
      return sequence if sequence&.any?
    end
    []
  end

  def x509_certificate_chain_to_root(cert, cert_root_id)
    signing_key_id = cert.signing_key_id
    return [] unless signing_key_id
    @certificates.values_at(
      *@graph.dijkstra_shortest_path(Hash.new(1), signing_key_id, cert_root_id)
    )
  end

  def delete(key)
    @graph.remove_vertex(key)
    @certificates.delete(key)
  end

  def remove_untrusted_certificates
    (@certificates.keys - trusted_certificate_ids).each(&method(:delete))
  end

  def all_certificates_valid?
    @certificates.values.all?(&:valid?)
  end

  def self.trusted_ca_root_identifiers
    @trusted_ca_root_identifiers ||=
      (Figaro.env.trusted_ca_root_identifiers || '').split(',').map(&:strip) - ['']
  end

  def self.clear_trusted_ca_root_identifiers
    @store = @trusted_ca_root_identifiers = nil
  end

  private

  def add_certificate_to_graph(key_id, cert)
    @certificates[key_id] = cert
    add_link(key_id, cert.signing_key_id)
  end

  # :reek:DuplicateMethodCall
  def trusted_certificate_ids
    # start with the trusted roots and work down
    trusted = trusted_ca_root_identifiers
    next_round = key_ids_signed_by(trusted)
    while next_round.any?
      trusted += next_round.map(&:key_id)
      next_round = key_ids_signed_by(trusted)
    end
    trusted
  end

  # :reek:FeatureEnvy
  def key_ids_signed_by(trusted)
    select do |cert|
      !trusted.include?(cert.key_id) && trusted.include?(cert.signing_key_id) && cert.valid?
    end
  end

  def extract_certs(raw)
    raw.split(END_CERTIFICATE).map(&method(:cert_from_pem)).compact.select(&:ca_capable?)
  end

  # :reek:UtilityFunction
  def cert_from_pem(pem)
    Certificate.new(OpenSSL::X509::Certificate.new(pem + END_CERTIFICATE)) if pem.strip.present?
  end
end
