unless File.basename($PROGRAM_NAME) == 'rake' && ARGV.any? { |arg| arg.start_with?('db:') }
  cert_store = CertificateStore.instance

  # load all of the files in config/certs
  Dir.chdir(Figaro.env.certificate_store_directory) do
    Dir.glob(File.join('**', '*.pem')).each do |file|
      next if file == 'all_certs_deploy.pem'
      cert_store.add_pem_file(file)
    end
  end
end
