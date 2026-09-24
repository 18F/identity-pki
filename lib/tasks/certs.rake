require 'open3'

namespace :certs do
  def ficam_bundle_file_path
    configured = IdentityConfig.store.ficam_certificate_bundle_file
    return configured if configured.present?

    Rails.root.join('config', 'cert_bundles', 'ficam_bundle.pem').to_s
  end

  desc 'Remove invalid certs, set EXPIRING=true to also remove certs expiring within 30 days'
  task remove_invalid: :environment do
    remove_expiring = (ENV['EXPIRING'] == 'true')
    deadline = 30.days.from_now

    Dir.glob(File.join('config', 'certs', '**', '*.pem')).each do |file|
      raw_cert = File.read(file)
      cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))

      if !cert.valid? || (remove_expiring && cert.expired?(deadline))
        warn "Removing invalid cert at #{file}"
        File.delete(file)
      end
    end
  end

  desc 'List all certs in the FICAM bundle'
  task list_ficam_certs: :environment do
    certs = OpenSSL::X509::Certificate.load_file(ficam_bundle_file_path).map do |x509|
      Certificate.new(x509)
    end

    puts "Found #{certs.length} certs in #{ficam_bundle_file_path}"
    certs.sort_by(&:not_after).each do |cert|
      puts "- Subject: #{cert.subject}"
      puts "  Issuer: #{cert.issuer}"
      puts "  Key ID: #{cert.key_id}"
      puts "  Expiration: #{cert.not_after}"
      puts "  Expired: #{cert.expired?}"
      puts "  Self-signed: #{cert.self_signed?}"
      puts "  OCSP URI: #{cert.ocsp_http_url}"
    end
  end

  desc 'Print expiring certs'
  task :print_expiring, [:deadline_days] => [:environment] do |t, args|
    args.with_defaults(deadline_days: 30)
    deadline = args[:deadline_days].to_i.days.from_now

    cert_store = CertificateStore.instance
    cert_store.load_certs!
    cert_store.add_pem_file(ficam_bundle_file_path)

    expiring_certs = cert_store.select do |cert|
      cert.expired?(deadline)
    end

    if expiring_certs.present?
      puts "Found certs expiring between now and #{deadline}"
      expiring_certs.each do |cert|
        puts "- Expiration: #{cert.not_after}"
        puts "  Subject: #{cert.subject}"
        puts "  Issuer: #{cert.issuer}"
        puts "  Key ID: #{cert.key_id}"
      end
      exit 1
    end
  end

  desc 'Validate FICAM certificate bundle exists and is properly formatted'
  task check_certificate_bundle: :environment do |t, args|
    ficam_bundle_file = ficam_bundle_file_path

    unless File.exist?(ficam_bundle_file)
      puts <<~ERROR
        FICAM certificate bundle not found at #{ficam_bundle_file}
        Please run:
        rake certs:generate_certificate_bundles
      ERROR
      exit 1
    end

    ficam_certificates = File.read(ficam_bundle_file).
      split(CertificateStore::END_CERTIFICATE).
      map do |cert|
      begin
        Certificate.new(OpenSSL::X509::Certificate.new(cert + CertificateStore::END_CERTIFICATE))
      rescue
        nil
      end
    end.
      compact

    if ficam_certificates.empty?
      puts <<~ERROR
        FICAM certificate bundle is empty at #{ficam_bundle_file}
        Please run:
        rake certs:generate_certificate_bundles
      ERROR
      exit 1
    end

    puts "✓ FICAM certificate bundle validated successfully (#{ficam_certificates.length} certificates found)"
  end

  desc 'Generate FICAM certificate bundle'
  task generate_certificate_bundles: :environment do |t, args|
    ficam_uri = URI('https://www.idmanagement.gov/implement/tools/CACertificatesValidatingToFederalCommonPolicyG2.p7b')
    federal_brige_ca_g4_key_id = '79:F0:00:49:EB:7F:77:C2:5D:41:02:65:34:8A:90:23:9B:1E:07:6F'

    response = Net::HTTP.get_response(ficam_uri)
    body = response.body.force_encoding('UTF-8')
    stdout, stderr, status = Open3.capture3(
      'openssl', 'pkcs7', '-print_certs', '-inform', 'PEM',
      stdin_data: body
    )
    raw_certificates = stdout.strip

    certificates = raw_certificates.split(CertificateStore::END_CERTIFICATE).map do |cert|
      cert += CertificateStore::END_CERTIFICATE
      cert = Certificate.new(OpenSSL::X509::Certificate.new(cert))
    end

    # Remove all certificates that are non-root cert and sign the Federal Bridge CA G4 cert
    # The current Federal Bridge CA G4 cert expires at 2029-12-06 16:52:46, and we may want to
    # monitor this as we approach that time.
    #
    # We could also engineer a more robust solution to circular cross-signed certificates that doesn't
    # rely on specific key IDs.
    certificates.reject! do |x|
      x.key_id == federal_brige_ca_g4_key_id &&
        !IdentityConfig.store.trusted_ca_root_identifiers.include?(x.signing_key_id)
    end

    File.write(
      ficam_bundle_file_path,
      certificates.sort_by(&:sha1_fingerprint).map(&:to_pem).join,
    )
  end

  task :validate_client_cert, [:cert_path] => [:environment] do |t, args|
    CertificateStore.instance.load_certs!

    raw_cert = File.read(args[:cert_path])
    certificate = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))

    validation_result = certificate.validate_cert

    if validation_result == 'valid'
      puts 'Certificate is valid!'
    else
      puts "Certificate is invalid: #{validation_result}"
    end
  end
end
