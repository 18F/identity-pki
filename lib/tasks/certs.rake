namespace :certs do
  desc 'Remove invalid certs'
  task remove_invalid: :environment do
    Dir.glob(File.join('config', 'certs', '**', '*.pem')).each do |file|
      raw_cert = File.read(file)
      cert = Certificate.new(OpenSSL::X509::Certificate.new(raw_cert))
      next if cert.valid?

      warn "Removing invalid cert at #{file}"
      File.delete(file)
    end
  end

  desc 'Print expiring certs'
  task print_expiring: :environment do
    deadline = 30.days.from_now

    expiring_certs = CertificateStore.instance.select do |cert|
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
