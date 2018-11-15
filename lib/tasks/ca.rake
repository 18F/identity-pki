namespace :ca do
  desc 'dump CA certificates'
  task dump: :environment do
    puts CertificateStore.instance.map { |_, cert| cert.to_pem }.join("\n")
  end

  desc 'graph CA certificate relationships'
  task graph: :environment do
    uml = +''
    uml << "@startuml\n"
    CertificateStore.instance.each do |cert|
      uml << "file \"#{cert.subject}\" as Cert#{cert.key_id.delete(':')}\n"
    end
    CertificateStore.instance.each do |cert|
      next if cert.trusted_root?
      uml << "Cert#{cert.signing_key_id.delete(':')} -down-> Cert#{cert.key_id.delete(':')}\n"
    end
    uml << "@enduml\n"

    puts uml
  end

  desc 'update CA certificates based on logged PIV/CAC certs'
  task update: :environment do
    CertificateIssuerUpdateService.new.call
  end
end
