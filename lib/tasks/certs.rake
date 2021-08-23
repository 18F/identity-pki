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
    puts 'Which cert(s) would you like to download? Use the format 1,2 if selecting multiple.'
    puts 'Press enter to skip'
    input = STDIN.gets.strip.split(',').map(&:to_i)
    puts ''

    return if input.blank?

    Array.wrap(matching_certs[*input]).each do |matching_cert|
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
end
