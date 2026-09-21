require 'open3'

namespace :certs do
  def ficam_bundle_file_path
    configured = IdentityConfig.store.ficam_certificate_bundle_file
    bundle_path = Pathname.new(
      configured.presence || Rails.root.join('config', 'cert_bundles', 'ficam_bundle.pem'),
    )
    bundle_path = Rails.root.join(bundle_path) unless bundle_path.absolute?

    bundle_path.to_s
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
    cert_store.load_certs!(dir: Rails.root.join('config/certs'))

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

  # Use only for missing certificates that are absent from the FICAM bundle.
  # ex: rake cert:find_missing_intermediate_certs[/my/path/to/cert.pem]
  desc 'Find missing intermediate certs absent from the FICAM bundle'
  task :find_missing_intermediate_certs, [:cert_path] => [:environment] do |t, args|
    cert = Certificate.new(OpenSSL::X509::Certificate.new(File.read(args[:cert_path])))
    missing_certs = CertificateChainService.new.missing(cert).uniq(&:key_id)
    missing_certs.reverse_each do |missing_cert|
      signing_cert = CertificateStore.instance[missing_cert.signing_key_id] ||
                     IssuingCaService.fetch_signing_key_for_cert(missing_cert)
      unless signing_cert
        puts 'Could not find signing certificate for missing certificate'
        next
      end

      found_cert = IssuingCaService.fetch_ca_repository_certs_for_cert(signing_cert).find do |x|
        x.key_id == missing_cert.key_id
      end
      unless found_cert
        puts 'Could not find missing certificate in signing key issued certificate'
        next
      end

      puts "  Expiration: #{found_cert.not_after}"
      puts "  Subject: #{found_cert.subject}"
      puts "  Issuer: #{found_cert.issuer}"
      puts "  SHA1 Fingerpint: #{found_cert.sha1_fingerprint}"
      puts "  Key ID: #{found_cert.key_id}"
      puts 'Would you like to save this cert? Type (y)es to save.'
      input = STDIN.gets.strip

      if input == 'yes' || input == 'y'
        path = Pathname.new('./config/certs') + found_cert.pem_filename

        if File.exist?(path)
          path = Pathname.new('./config/certs') + found_cert.pem_filename(
            suffix: " #{found_cert.not_after.to_i}",
          )
        end
        puts "Writing certificate to #{path}"
        File.write(path, found_cert.to_pem)
        CertificateStore.instance.load_certs!
      end
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

    certificate_segments = File.read(ficam_bundle_file).
      split(CertificateStore::END_CERTIFICATE).
      reject { |segment| segment.strip.empty? }
    ficam_certificates = certificate_segments.map do |segment|
      pem = segment + CertificateStore::END_CERTIFICATE
      Certificate.new(OpenSSL::X509::Certificate.new(pem))
    end

    if ficam_certificates.none?(&:ca_capable?)
      puts <<~ERROR
        FICAM certificate bundle contains no CA certificates at #{ficam_bundle_file}
        Please run:
        rake certs:generate_certificate_bundles
      ERROR
      exit 1
    end

    puts "✓ FICAM certificate bundle validated successfully " \
      "(#{ficam_certificates.length} certificates found)"
  end

  desc 'Generate FICAM certificate bundle'
  task generate_certificate_bundles: :environment do |t, args|
    ficam_uri = URI('https://www.idmanagement.gov/implement/tools/CACertificatesValidatingToFederalCommonPolicyG2.p7b')
    federal_bridge_ca_g4_key_id = '79:F0:00:49:EB:7F:77:C2:5D:41:02:65:34:8A:90:23:9B:1E:07:6F'

    response = Net::HTTP.get_response(ficam_uri)
    unless response.is_a?(Net::HTTPSuccess)
      raise "Could not download FICAM bundle: HTTP #{response.code}"
    end

    stdout, stderr, status = Open3.capture3(
      'openssl', 'pkcs7', '-print_certs', '-inform', 'PEM',
      stdin_data: response.body
    )
    raise "Could not convert FICAM bundle: #{stderr.strip}" unless status.success?

    raw_certificates = stdout.strip
    raise 'Converted FICAM bundle is empty' if raw_certificates.empty?

    certificates = raw_certificates.split(CertificateStore::END_CERTIFICATE).filter_map do |cert|
      next if cert.strip.empty?

      Certificate.new(OpenSSL::X509::Certificate.new(cert + CertificateStore::END_CERTIFICATE))
    end

    # Remove all certificates that are non-root cert and sign the Federal Bridge CA G4 cert
    # The current Federal Bridge CA G4 cert expires at 2029-12-06 16:52:46, and we may want to
    # monitor this as we approach that time.
    #
    # We could also engineer a more robust solution to circular cross-signed certificates that
    # doesn't rely on specific key IDs.
    certificates.reject! do |x|
      x.key_id == federal_bridge_ca_g4_key_id &&
        !IdentityConfig.store.trusted_ca_root_identifiers.include?(x.signing_key_id)
    end

    File.write(
      ficam_bundle_file_path,
      certificates.sort_by(&:sha1_fingerprint).map(&:to_pem).join,
    )
  end

  task :validate_client_cert, [:cert_path] => [:environment] do |t, args|
    CertificateStore.instance.load_certs!(dir: 'config/certs')

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
