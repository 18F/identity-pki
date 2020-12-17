unless File.basename($PROGRAM_NAME) == 'rake' && ARGV.any? { |arg| arg.start_with?('db:') }
  CertificateStore.instance.load_certs!
end
