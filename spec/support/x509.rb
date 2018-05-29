require 'openssl'

module X509Helpers
  # Keep keys short so testing is faster and doesn't use as much random data.
  # We aren't making real certificates, just realistic ones.
  RSA_KEY_SIZE = 512

  AUTHORITY_INFO_ACCESS_EXTENSION = [
    'authorityInfoAccess',
    'caIssuers;URI:http://example.com/,OCSP;URI:http://ocsp.example.com/',
    false,
  ].freeze

  ##
  # Requires:
  # ca: the issuing cert
  # ca_key: the key pair for the issuing cert
  # serials: list of serial numbers
  #
  def create_crl(info = {})
    root_ca = info[:ca]
    root_key = info[:ca_key]

    crl = OpenSSL::X509::CRL.new
    crl.issuer = root_ca.subject
    crl.version = 1
    crl.last_update = Time.zone.now
    crl.next_update = Time.zone.now + 12.hours
    info[:serials].map do |serial|
      revocation = OpenSSL::X509::Revoked.new
      revocation.serial = OpenSSL::BN.new(serial)
      revocation.time = Time.zone.now
      enum = OpenSSL::ASN1::Enumerated(1)
      ext = OpenSSL::X509::Extension.new('CRLReason', enum)
      revocation.add_extension(ext)
      crl.add_revoked(revocation)
    end
    crl.sign(root_key, OpenSSL::Digest::SHA256.new)
    crl
  end

  ##
  # Requires:
  #   dn: subject of the cert
  #   serial: serial number of the cert
  #   not_before: start date of cert
  #   not_after: end date of cert
  #
  def create_root_certificate(info = {})
    root_key = OpenSSL::PKey::RSA.new(RSA_KEY_SIZE)
    root_ca = create_certificate_skeleton(info)

    root_ca.issuer = root_ca.subject
    root_ca.public_key = root_key.public_key

    add_certificate_extensions(root_ca, root_ca,
                               ['basicConstraints', 'CA:TRUE', true],
                               ['keyUsage', 'keyCertSign, cRLSign', true],
                               ['subjectKeyIdentifier', 'hash', false],
                               ['authorityKeyIdentifier', 'keyid:always', false])
    root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
    [root_ca, root_key]
  end

  ##
  # Requires:
  #   ca: issuing cert
  #   ca_key: key pair of issuing cert
  #   dn: subject of the cert
  #   serial: serial number of the cert
  #   not_before: start date of cert
  #   not_after: end date of cert
  #
  def create_intermediate_certificate(info = {})
    root_ca = info[:ca]
    root_key = info[:ca_key]

    key = OpenSSL::PKey::RSA.new(RSA_KEY_SIZE)

    cert = create_certificate_skeleton(info)
    cert.issuer = root_ca.subject # root CA is the issuer
    cert.public_key = key.public_key

    add_certificate_extensions(cert, root_ca,
                               ['basicConstraints', 'CA:TRUE', true],
                               ['keyUsage', 'keyCertSign, cRLSign', true],
                               AUTHORITY_INFO_ACCESS_EXTENSION,
                               ['subjectKeyIdentifier', 'hash', false],
                               ['authorityKeyIdentifier', 'keyid:always', false])
    cert.sign(root_key, OpenSSL::Digest::SHA256.new)
    [cert, key]
  end

  ##
  # Requires:
  #   ca: issuing cert
  #   ca_key: key pair of issuing cert
  #   dn: subject of the cert
  #   serial: serial number of the cert
  #   not_before: start date of cert
  #   not_after: end date of cert
  #
  def create_leaf_certificate(info = {})
    root_ca = info[:ca]
    root_key = info[:ca_key]

    key = OpenSSL::PKey::RSA.new(RSA_KEY_SIZE)

    cert = create_certificate_skeleton(info)
    cert.issuer = root_ca.subject # root CA is the issuer
    cert.public_key = key.public_key

    add_certificate_extensions(cert, root_ca,
                               ['keyUsage', 'digitalSignature', true],
                               ['subjectKeyIdentifier', 'hash', false],
                               AUTHORITY_INFO_ACCESS_EXTENSION,
                               ['authorityKeyIdentifier', 'keyid:always', false])
    cert.sign(root_key, OpenSSL::Digest::SHA256.new)
    cert
  end

  ##
  # Output is a list of certificates.
  def create_certificate_set(root_count:, intermediate_count:, leaf_count:)
    # we create the number of trusted roots, then for each root, the intermediates,
    # and for each intermediate, the leaves
    root_certs = []
    intermediate_certs = []
    leaf_certs = []
    root_count.times do |root_index|
      root, root_key = create_root_certificate(
        dn: "DC=com, DC=example, OU=ca, CN=Root #{root_index + 1}",
        serial: root_index + 1
      )
      root_certs << root
      intermediate_count.times do |intermediate_index|
        intermediate, intermediate_key = create_intermediate_certificate(
          dn: [
            'DC=com',
            'DC=example',
            'OU=ca',
            "CN=Intermediate #{root_index + 1}-#{intermediate_index + 1}",
          ].join(' '),
          serial: intermediate_index + 1,
          ca: root,
          ca_key: root_key
        )
        intermediate_certs << intermediate
        leaf_count.times do |leaf_index|
          cn_number = root_index * intermediate_count +
                      intermediate_index * leaf_count +
                      leaf_index
          leaf = create_leaf_certificate(
            dn: [
              'DC=com',
              'DC=example',
              'OU=foo',
              "CN=bar #{cn_number}",
            ].join(' '),
            serial: leaf_index + 1,
            ca: intermediate,
            ca_key: intermediate_key
          )
          leaf_certs << leaf
        end
      end
    end
    [root_certs, intermediate_certs, leaf_certs]
  end

  private

  def create_certificate_skeleton(info = {})
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = info[:serial]
    cert.subject = OpenSSL::X509::Name.parse info[:dn]
    cert.not_before = info[:not_before] || Time.zone.now - 1.year
    cert.not_after = info[:not_after] || cert.not_before + 2.years
    cert
  end

  def add_certificate_extensions(cert, issuer_cert, *extension_list)
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = issuer_cert
    extension_list.each do |oid, value, crit|
      cert.add_extension(ef.create_extension(oid, value, crit))
    end
  end
end

RSpec.configure do |c|
  c.include X509Helpers
end
