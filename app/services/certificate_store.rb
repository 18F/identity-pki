require 'openssl'
require 'rgl/dijkstra'
require 'rgl/adjacency'

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

  def_delegators :@certificates, :[], :count, :empty?
  def_delegators CertificateStore, :trusted_ca_root_identifiers, :clear_trusted_ca_root_identifiers

  def add_pem_file(filename)
    raw = IO.binread(filename)
    certs = extract_certs(raw)
    certs.each(&method(:add_certificate))
  end

  def add_link(from, to)
    @graph.add_vertex(from) if from
    @graph.add_vertex(to) if to
    @graph.add_edge(from, to) if from && to
  end

  def add_certificate(cert)
    key_id = cert.key_id
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
    loop do
      break unless sweep_untrusted_certificates
    end
  end

  def all_certificates_valid?
    @certificates.values.all?(&:valid?)
  end

  class << self
    def trusted_ca_root_identifiers
      @trusted_ca_root_identifiers ||= begin
        raw = Figaro.env.trusted_ca_root_identifiers || ''
        raw.split(',').map(&:strip) - ['']
      end
    end

    def clear_trusted_ca_root_identifiers
      @trusted_ca_root_identifiers = nil
    end
  end

  private

  def sweep_untrusted_certificates
    # linters like this bit of golf:
    #   we map each key to the result of deleting it, if we delete it
    #   `delete` returns non-nil, which we then use `any?` to detect
    # The goal is to return a truthy value if we deleted anything.
    swept = @certificates.values.reject(&:trusted_root?).reject(&:valid?)
    swept.map(&:key_id).map(&method(:delete)).any?
  end

  def extract_certs(raw)
    raw.
      split(END_CERTIFICATE).
      map(&method(:cert_from_pem)).
      compact.
      select(&:ca_capable?)
  end

  # :reek:UtilityFunction
  def cert_from_pem(pem)
    return if pem =~ /\A\s*\Z/
    Certificate.new(OpenSSL::X509::Certificate.new(pem + END_CERTIFICATE))
  end
end
