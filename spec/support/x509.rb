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

  CA_CONFIG = OpenSSL::Config.parse(<<~SSL_CONFIG)
    oid_section = new_oids
     [ new_oids ]
    id-US-dod-mediumHardware-112 = 2.16.840.1.101.2.1.11.42
    id-US-dod-mediumHardware-128 = 2.16.840.1.101.2.1.11.43
    id-US-dod-mediumHardware-192 = 2.16.840.1.101.2.1.11.44
    id-fpki-common-hardware = 2.16.840.1.101.3.2.1.3.7
    id-fpki-common-authentication = 2.16.840.1.101.3.2.1.3.13
  SSL_CONFIG

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

  OCSP_STATUS = begin
    hash = Hash.new(OpenSSL::OCSP::V_CERTSTATUS_GOOD)
    hash[:revoked] = OpenSSL::OCSP::V_CERTSTATUS_REVOKED
    hash
  end

  # :reek:ControlParameter
  # :reek:BooleanParameter
  # :reek:LongParameterList
  def create_ocsp_response(request_der, cert_collection, status_enum = :valid, valid_ocsp = true)
    request = OpenSSL::OCSP::Request.new(request_der)
    status = OCSP_STATUS[status_enum]

    request.certid.map do |certificate_id|
      cert_info = cert_for_id(certificate_id, cert_collection)
      next unless cert_info
      basic_response = OpenSSL::OCSP::BasicResponse.new
      basic_response.copy_nonce(request)
      basic_response.add_status(certificate_id, status, 0,
                                1.day.ago, Time.zone.now, Time.zone.now + 1.day, nil)
      issuer_id = cert_info[:signing_cert_id]
      issuer_info = cert_for_id(issuer_id, cert_collection)
      issuer = issuer_info[:certificate]
      signing_key = issuer_info[:key]
      basic_response.sign(issuer.x509_cert, signing_key, [])
      OpenSSL::OCSP::Response.create(valid_ocsp ? 0 : 1, basic_response).to_der
    end.join('')
  end

  # :reek:ControlParameter
  # :reek:LongParameterList
  def create_bad_ocsp_response(request_der, cert_collection, status_enum = :valid, factor = :nonce)
    request = OpenSSL::OCSP::Request.new(request_der)
    status = OCSP_STATUS[status_enum]

    request.certid.map do |certificate_id|
      cert_info = cert_for_id(certificate_id, cert_collection)
      next unless cert_info
      basic_response = OpenSSL::OCSP::BasicResponse.new
      if factor == :nonce
        basic_response.add_nonce
      else
        basic_response.copy_nonce(request)
      end
      basic_response.add_status(certificate_id, status, 0,
                                1.day.ago, Time.zone.now, Time.zone.now + 1.day, nil)
      issuer_id = cert_info[:signing_cert_id]
      issuer_info = if factor == :signing_key
                      random_issuer(issuer_id, cert_collection)
                    else
                      cert_for_id(issuer_id, cert_collection)
                    end
      issuer = issuer_info[:certificate]
      signing_key = issuer_info[:key]
      basic_response.sign(issuer.x509_cert, signing_key, [])
      OpenSSL::OCSP::Response.create(status, basic_response).to_der
    end.join('')
  end

  def random_issuer(id_to_avoid, cert_collection)
    cert_collection.detect do |info|
      !id_to_avoid.cmp(info[:cert_id]) && info[:key]
    end
  end

  def cert_for_id(cert_id, cert_collection)
    cert_collection.detect do |info|
      cert_id.cmp(info[:cert_id])
    end
  end

  ##
  # Requires:
  #   dn: subject of the cert
  #   serial: serial number of the cert
  #   not_before: start date of cert
  #   not_after: end date of cert
  #   policies: # optional list of policies
  #   policy_mapping: # optional mapping of policies
  #   policy_constraints: # optional mapping of policy constraints
  def create_root_certificate(info = {})
    root_key = OpenSSL::PKey::RSA.new(RSA_KEY_SIZE)
    root_ca = create_certificate_skeleton(info)

    root_ca.issuer = root_ca.subject
    root_ca.public_key = root_key.public_key

    extensions = [
      ['basicConstraints', 'CA:TRUE', true],
      ['keyUsage', 'keyCertSign, cRLSign', true],
      ['subjectKeyIdentifier', 'hash', false],
      ['authorityKeyIdentifier', 'keyid:always', false],
    ]

    if info[:policy_constraints]
      extensions << [
        'policyConstraints',
        info[:policy_constraints].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    if info[:policy_mapping]
      extensions << [
        'policyMappings',
        info[:policy_mapping].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    add_certificate_extensions(root_ca, root_ca, *extensions)
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

    extensions = [
      ['basicConstraints', 'CA:TRUE', true],
      ['keyUsage', 'keyCertSign, cRLSign', true],
      AUTHORITY_INFO_ACCESS_EXTENSION,
      ['subjectKeyIdentifier', 'hash', false],
      ['authorityKeyIdentifier', 'keyid:always', false],
    ]

    if info[:policy_constraints]
      extensions << [
        'policyConstraints',
        info[:policy_constraints].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    if info[:policy_mapping]
      extensions << [
        'policyMappings',
        info[:policy_mapping].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    add_certificate_extensions(cert, root_ca, *extensions)
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

    extensions = [
      ['keyUsage', 'digitalSignature', true],
      ['subjectKeyIdentifier', 'hash', false],
      AUTHORITY_INFO_ACCESS_EXTENSION,
      ['authorityKeyIdentifier', 'keyid:always', false],
    ]

    unless info[:no_policies]
      extensions << [
        'certificatePolicies',
        JSON.parse(Figaro.env.required_policies).first,
        false,
      ]
    end

    if info[:policy_constraints]
      extensions << [
        'policyConstraints',
        info[:policy_constraints].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    if info[:policy_mapping]
      extensions << [
        'policyMappings',
        info[:policy_mapping].to_a.map { |kv| kv.join(':') }.join(','),
        true,
      ]
    end

    add_certificate_extensions(cert, root_ca, *extensions)
    cert.sign(root_key, OpenSSL::Digest::SHA256.new)
    cert
  end

  ##
  # Output is a list of certificates.
  def create_certificate_set(**options)
    # we create the number of trusted roots, then for each root, the intermediates,
    # and for each intermediate, the leaves
    root_certs = []
    intermediate_certs = []
    leaf_certs = []
    root_options = options[:root_options] || {}
    intermediate_options = options[:intermediate_options] || {}
    leaf_options = options[:leaf_options] || {}
    options[:root_count].times do |root_index|
      root, root_key = create_root_certificate(
        dn: "DC=com, DC=example, OU=ca, CN=Root #{root_index + 1}",
        serial: root_index + 1,
        **root_options
      )
      root_cert_id = OpenSSL::OCSP::CertificateId.new(
        root, root, OpenSSL::Digest::SHA1.new
      )
      root_certs << {
        type: :root,
        certificate: Certificate.new(root),
        key: root_key,
        signing_cert_id: root_cert_id,
        cert_id: root_cert_id,
      }
      options[:intermediate_count].times do |intermediate_index|
        intermediate, intermediate_key = create_intermediate_certificate(
          dn: [
            'DC=com',
            'DC=example',
            'OU=ca',
            "CN=Intermediate #{root_index + 1}-#{intermediate_index + 1}",
          ].join(' '),
          serial: intermediate_index + 1,
          ca: root,
          ca_key: root_key,
          **intermediate_options
        )
        intermediate_cert_id = OpenSSL::OCSP::CertificateId.new(
          intermediate, root, OpenSSL::Digest::SHA1.new
        )
        intermediate_certs << {
          type: :intermediate,
          certificate: Certificate.new(intermediate),
          key: intermediate_key,
          signing_cert_id: root_cert_id,
          cert_id: intermediate_cert_id,
        }
        options[:leaf_count].times do |leaf_index|
          cn_number = root_index * options[:intermediate_count] +
                      intermediate_index * options[:leaf_count] +
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
            ca_key: intermediate_key,
            **leaf_options
          )
          leaf_cert_id = OpenSSL::OCSP::CertificateId.new(
            leaf, intermediate, OpenSSL::Digest::SHA1.new
          )
          leaf_certs << {
            type: :leaf,
            certificate: Certificate.new(leaf),
            signing_cert_id: intermediate_cert_id,
            cert_id: leaf_cert_id,
          }
        end
      end
    end
    root_certs + intermediate_certs + leaf_certs
  end

  def certificates_in_collection(collection, key, value)
    collection.
      select { |info| info[key] == value }.
      map { |info| info[:certificate] }
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
    ef.config = CA_CONFIG
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
