require 'rails_helper'

describe 'Certificate store in config/certs' do
  before do
    # We need to allow net connect to download CRLs and check for revocations
    WebMock.disallow_net_connect!(
      allow: ['ocsp.disa.mil',
              'ssp-ocsp.symauth.com',
              'ocsp.managed.entrust.com',
              'ocsp1.ssp-strong-id.net',
              'ocsp.pki.state.gov',
              'nfiocsp.managed.entrust.com',
              'ssp-ocsp.digicert.com',
              'ocsp.uspto.gov'],
    )

    Dir.glob(File.join('config', 'certs', '**', '*.pem')).each do |file|
      CertificateStore.instance.add_pem_file(file)
    end

    # Load the FICAM bundle so the intermediate and root CA certs needed to
    # verify the certs we maintain in config/certs (e.g. cross-signed roots)
    # are present in the store.
    CertificateStore.instance.add_pem_file(
      File.join('config', 'cert_bundles', 'ficam_bundle.pem'),
    )
  end

  after do
    WebMock.disallow_net_connect!
  end

  it 'only contains valid certs' do
    # config/certs may be empty when all certs are provided by the ficam bundle
    config_certs = Dir.glob(File.join('config', 'certs', '**', '*.pem')).flat_map do |file|
      CertificateStore.instance.add_pem_file(file)
    end

    invalid_certs = config_certs.filter do |cert|
      cert.token({})
      !cert.valid?
    end

    invalid_cert_list = invalid_certs.map do |invalid_cert|
      "#{invalid_cert.subject} : #{invalid_cert.validate_cert}"
    end.join("\n")
    failure_message = <<~MESSAGE
      Invalid certs found:
      #{invalid_cert_list}

      Use `rake certs:remove_invalid` to remove them
    MESSAGE

    expect(invalid_certs).to be_empty, failure_message
  end

  it 'does not contain duplicate certs' do
    certs_by_key_id = {}
    Dir.glob(File.join('config', 'certs', '**', '*.pem')).each do |file|
      raw_cert = File.read(file)
      cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))
      certs_by_key_id[cert.key_id] ||= []
      certs_by_key_id[cert.key_id].push(cert)
    end

    duplicate_certs = certs_by_key_id.values.filter(&:many?)

    duplicate_cert_list = duplicate_certs.map do |cert_list|
      cert_list.map(&:subject).join("\n")
    end.join("\n----------------------------\n")
    failure_message = "Duplicate certs found:\n#{duplicate_cert_list}"

    expect(duplicate_certs).to be_empty, failure_message
  end

  it 'does not contain certs that are already in the ficam bundle' do
    ficam_bundle_raw = File.read(File.join('config', 'cert_bundles', 'ficam_bundle.pem'))
    ficam_key_ids = ficam_bundle_raw.split(CertificateStore::END_CERTIFICATE).filter_map do |pem|
      next if pem.strip.blank?

      Certificate.new(OpenSSL::X509::Certificate.new(pem + CertificateStore::END_CERTIFICATE)).key_id
    end

    duplicated_certs = Dir.glob(File.join('config', 'certs', '**', '*.pem')).filter do |file|
      raw_cert = File.read(file)
      cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))
      ficam_key_ids.include?(cert.key_id)
    end

    failure_message = <<~MESSAGE
      Certs found in config/certs that already exist in the ficam bundle:
      #{duplicated_certs.join("\n")}

      Remove these files; they are already provided by config/cert_bundles/ficam_bundle.pem
    MESSAGE

    expect(duplicated_certs).to be_empty, failure_message
  end
end
