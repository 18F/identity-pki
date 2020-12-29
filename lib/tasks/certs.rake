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
end
