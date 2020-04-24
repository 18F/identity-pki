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
end
