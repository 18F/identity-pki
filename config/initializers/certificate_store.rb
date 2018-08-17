unless File.basename($PROGRAM_NAME) == 'rake' && ARGV.any? { |arg| arg.start_with?('db:') }
  cert_store = CertificateStore.instance

  # load all of the files in config/certs
  Dir.chdir(Figaro.env.certificate_store_directory) do
    Dir.glob(File.join('**', '*')).each do |file|
      cert_store.add_pem_file(file)
    end
  end

  cert_store.remove_untrusted_certificates

  unless cert_store.all_certificates_valid?
    raise 'Not all certificates in the certificate store can be trusted'
  end

  raise 'There are no trusted certificates available' if cert_store.empty? && Rails.env.production?
end
