require 'open3'

namespace :certs do
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

  desc 'Print expiring certs'
  task print_expiring: :environment do
    deadline = 30.days.from_now

    cert_store = CertificateStore.instance
    cert_store.load_certs!(dir: Rails.root.join('config/certs'))

    expiring_certs = cert_store.select do |cert|
      cert.expired?(deadline)
    end

    if expiring_certs.present?
      puts "Expiring Certs found, deadline: #{deadline}"
      expiring_certs.each do |cert|
        puts "- Expiration: #{cert.not_after}"
        puts "  Subject: #{cert.subject}"
        puts "  Issuer: #{cert.issuer}"
        puts "  Key ID: #{cert.key_id}"
      end
      exit 1
    end
  end

  # Per https://fpki.idmanagement.gov/tools/fpkigraph/:
  # >Most CA certificates will also have an SIA extension with a URI to the CA certificates
  # >that have been issued by that CA.
  #
  # This task takes a key_id as an argument and fetches that cert from the Certificate Store.
  # If the cert exists, the signing cert is fetched from the Certificate Store.
  # If the signing cert has a subject information access extension with a 'CA Repository' key,
  # the bundle is downloaded. This bundle should contain all of the certs signed by the expiring
  # cert's signing cert.
  #
  # There isn't a guaranteed way to associate an expiring cert with its replacment(s), so we try to
  # match on the subject.
  desc 'Find replacement cert'
  task :find_replacement, [:key_id] => [:environment] do |t, args|
    cert_store = CertificateStore.instance
    cert_store.load_certs!(dir: Rails.root.join('config/certs'))
    key_id = args[:key_id]

    cert = CertificateStore.instance[key_id]
    raise "Cert #{key_id} is not in CertificateStore" if cert.nil?
    signing_cert = CertificateStore.instance[cert.signing_key_id] ||
      IssuingCaService.fetch_signing_key_for_cert(cert)

    raise "Signing cert #{cert.signing_key_id} is not in store and could not be downloaded" if signing_cert.nil?

    puts "Signing Cert subject information access (SIA) extensions: #{signing_cert.subject_info_access.inspect}"

    repository_certs = IssuingCaService.fetch_ca_repository_certs_for_cert(signing_cert)
    raise "Signing cert #{cert.signing_key_id} is not in store and could not be downloaded" if signing_cert.nil?

    matching_certs = repository_certs.select do |repo_cert|
      repo_cert.serial != cert.serial &&
        repo_cert.ca_capable? &&
        DidYouMean::JaroWinkler.distance(repo_cert.subject.to_s, cert.subject.to_s) > 0.95
    end
    raise "No matching certs in the signing cert's CA repository" if matching_certs.empty?

    puts "Expiring Certificate:"
    puts "  Expiration: #{cert.not_after}"
    puts "  Subject: #{cert.subject}"
    puts "  Issuer: #{cert.issuer}"
    puts "  SHA1 Fingerpint: #{cert.sha1_fingerprint}"
    puts "  Key ID: #{cert.key_id}"

    puts ""
    puts "Potential Replacement Certificates:"
    matching_certs.each_with_index do |matching_cert, index|
      puts "- Index: #{index}"
      puts "  Expiration: #{matching_cert.not_after}"
      puts "  Subject: #{matching_cert.subject}"
      puts "  Issuer: #{matching_cert.issuer}"
      puts "  SHA1 Fingerpint: #{matching_cert.sha1_fingerprint}"
      puts "  Key ID: #{matching_cert.key_id}"
      puts "  In Certificate Store: #{CertificateStore.instance[matching_cert.key_id].present?}"
    end

    puts ''
    puts 'Which cert(s) would you like to download? Use the format 1,2 if selecting multiple or ALL for all'
    puts 'Press enter to skip'
    raw_input = STDIN.gets.strip
    input = raw_input == 'ALL' ? 0...matching_certs.length : raw_input.split(',').map(&:to_i)
    puts ''

    return if input.blank?

    Array.wrap(matching_certs.values_at(*input)).each do |matching_cert|
      path = Pathname.new("./config/certs") + matching_cert.pem_filename

      if File.exist?(path)
        path = Pathname.new("./config/certs") + matching_cert.pem_filename(
          suffix: " #{matching_cert.not_after.to_i}"
        )
      end
      puts "Writing certificate to #{path}"
      File.write(path, matching_cert.to_pem)
    end

    puts ''
    puts 'Double check https://fpki.idmanagement.gov/notifications/#notifications for new and revoked certs'
  end

  # This task uses existing certificates' CA Repository information from the subject information
  # access extension to see if existing certs have issued any certificates that we do not have.
  # The find_replacement task is helpful for expiring certificates, but this task is useful
  # when a certificate authority has issued new certificates that are not replacements.
  # Currently, the task only fetches certs issued by our trusted root certificates, but could be
  # modified to go deeper in the issuing tree.
  desc 'Find certs issued by existing certs'
  task find_new: :environment do
    root_keys = IdentityConfig.store.trusted_ca_root_identifiers + IdentityConfig.store.dod_root_identifiers
    root_keys.each do |key_id|
      root_cert = CertificateStore.instance[key_id]
      repository_certs = IssuingCaService.fetch_ca_repository_certs_for_cert(root_cert)

      repository_certs.each do |repo_cert|
        next if CertificateStore.instance.certificates.any? { |x| x.serial == repo_cert.serial }

        puts "  Expiration: #{repo_cert.not_after}"
        puts "  Subject: #{repo_cert.subject}"
        puts "  Issuer: #{repo_cert.issuer}"
        puts "  SHA1 Fingerpint: #{repo_cert.sha1_fingerprint}"
        puts "  Key ID: #{repo_cert.key_id}"
        puts "  In Certificate Store: #{CertificateStore.instance[repo_cert.key_id].present?}"
        puts "Would you like to save this cert? Type (y)es to save."
        input = STDIN.gets.strip

        if input == 'yes' || input == 'y'
          path = Pathname.new("./config/certs") + repo_cert.pem_filename

          if File.exist?(path)
            path = Pathname.new("./config/certs") + repo_cert.pem_filename(
              suffix: " #{repo_cert.not_after.to_i}"
            )
          end
          puts "Writing certificate to #{path}"
          File.write(path, repo_cert.to_pem)
          CertificateStore.instance.load_certs!
        end
      end
    end
  end

  # Using a cert downloaded from https://handbook.login.gov/articles/troubleshooting-pivcacs.html
  # ex: rake cert:find_missing_intermediate_certs[/my/path/to/cert.pem]
  desc 'Find missing intermediate_certs certs for a specific cert'
  task :find_missing_intermediate_certs, [:cert_path] => [:environment] do |t, args|
    cert = Certificate.new(OpenSSL::X509::Certificate.new(File.read(args[:cert_path])))
    missing_certs = CertificateChainService.new.missing(cert).uniq(&:key_id)
    missing_certs.reverse.each do |missing_cert|
      signing_cert = CertificateStore.instance[missing_cert.signing_key_id]
      unless signing_cert
        put 'Could not find signing certificate for missing certificate'
        next
      end

      found_cert = IssuingCaService.fetch_ca_repository_certs_for_cert(signing_cert).find { |x| x.key_id == missing_cert.key_id }
      unless found_cert
        put 'Could not find missing certificate in signing key issued certificate'
        next
      end


      puts "  Expiration: #{found_cert.not_after}"
      puts "  Subject: #{found_cert.subject}"
      puts "  Issuer: #{found_cert.issuer}"
      puts "  SHA1 Fingerpint: #{found_cert.sha1_fingerprint}"
      puts "  Key ID: #{found_cert.key_id}"
      puts "Would you like to save this cert? Type (y)es to save."
      input = STDIN.gets.strip

      if input == 'yes' || input == 'y'
        path = Pathname.new("./config/certs") + found_cert.pem_filename

        if File.exist?(path)
          path = Pathname.new("./config/certs") + found_cert.pem_filename(
            suffix: " #{found_cert.not_after.to_i}"
          )
        end
        puts "Writing certificate to #{path}"
        File.write(path, found_cert.to_pem)
        CertificateStore.instance.load_certs!
      end
    end
  end



  desc 'Check that LG certificate bundle matches certificates in certificate path'
  task check_certificate_bundle: :environment do |t, args|
    CertificateStore.instance.load_certs!(dir: 'config/certs')
    bundled_certs = []
    cert_bundle_file = File.read(IdentityConfig.store.login_certificate_bundle_file)
    cert_bundle = cert_bundle_file.split(CertificateStore::END_CERTIFICATE).map do |cert|
      cert += CertificateStore::END_CERTIFICATE
      cert = Certificate.new(OpenSSL::X509::Certificate.new(cert))
    end

    if cert_bundle.map(&:sha1_fingerprint).sort != CertificateStore.instance.certificates.map(&:sha1_fingerprint).sort
      puts <<-ERROR
        #{IdentityConfig.store.login_certificate_bundle_file} does not match the certificates in #{IdentityConfig.store.certificate_store_directory}
        Please run:
        rake certs:generate_certificate_bundle
      ERROR
      exit 1
    end
  end

  task generate_certificate_bundles: :environment do |t, args|
    CertificateStore.instance.load_certs!(dir: 'config/certs')
    File.write(
      IdentityConfig.store.login_certificate_bundle_file,
      CertificateStore.instance.certificates.sort_by(&:sha1_fingerprint).map(&:to_pem).join,
    )

    ficam_uri = URI('https://raw.githubusercontent.com/GSA/ficam-playbooks/staging/_fpki/tools/CACertificatesValidatingToFederalCommonPolicyG2.p7b')
    federal_brige_ca_g4_key_id = '79:F0:00:49:EB:7F:77:C2:5D:41:02:65:34:8A:90:23:9B:1E:07:6F'

    response = Net::HTTP.get_response(ficam_uri)
    body = response.body.force_encoding('UTF-8')
    stdout, stderr, status = Open3.capture3('openssl', 'pkcs7', '-print_certs', '-inform', 'DER', stdin_data: body)
    raw_certificates = stdout.strip

    certificates = raw_certificates.split(CertificateStore::END_CERTIFICATE).map do |cert|
      cert += CertificateStore::END_CERTIFICATE
      cert = Certificate.new(OpenSSL::X509::Certificate.new(cert))
    end

    # Remove all certificates that are non-root cert and sign the Federal Bridge CA G4 cert
    certificates.reject! do |x|
      (x.key_id == federal_brige_ca_g4_key_id &&
       !IdentityConfig.store.trusted_ca_root_identifiers.include?(x.signing_key_id))
    end

    File.write(
      IdentityConfig.store.ficam_certificate_bundle_file,
      certificates.sort_by(&:sha1_fingerprint).map(&:to_pem).join,
    )
  end
end
