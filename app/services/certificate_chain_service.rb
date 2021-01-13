class CertificateChainService
  # Gets the chain of Cerificates between this cert and the root
  # @param [Certificate]
  # @return [Array<Certificate>]
  def chain(cert)
    process_unknown_certs(cert.signing_key_id, cert.ca_issuer_http_url)
  end

  # Gets the chain of Certificates and also prints them out
  # @param [Certificate]
  # @return [Array<Certificate>]
  def debug(cert)
    chain(cert).each_with_index { |cert, step| print_cert(cert, step) }
  end

  # Finds the missing certs in the chain and writes them to the config/certs repo
  # @param [Certificate]
  def missing(cert)
    chain(cert).reject { |cert| CertificateStore.instance[cert.key_id] }
  end

  # @return [Array<Certificate>]
  def process_unknown_certs(ca_id, ca_issuer_url, new_certs = [])
    ca_id.upcase!
    ca_cert = get_cert_from_issuer(ca_id, ca_issuer_url)
    process_certificate_chain(ca_cert)
  end

  # @return [Array<Certificate>]
  def process_certificate_chain(ca_cert, chain_array = [], step = 0)
    chain_array << ca_cert
    issuer_ca_cert = get_cert_from_issuer(ca_cert.signing_key_id, ca_cert.issuer_metadata[:ca_issuer_url])
    step += 1
    if step <= 6 && !issuer_ca_cert.trusted_root?
      process_certificate_chain(issuer_ca_cert, chain_array, step)
    end
    chain_array
  end

  # @api private
  # @param [Certificate] cert
  def print_cert(cert, step)
    puts "///////////////////////////////////////"
    puts "///////////// [ CA Step: #{step} ] /////////////"
    puts "///////////////////////////////////////"
    puts "#{cert.to_pem}"
    puts "key_id: #{cert.key_id}"
    puts "signing_key_id: #{cert.signing_key_id}"
    puts "ca_issuer_dn: #{cert.issuer_metadata[:dn]}"
    puts "ca_issuer_url: #{cert.issuer_metadata[:ca_issuer_url]}"
  end

  def get_cert_from_issuer(ca_id, ca_issuer_url)
    STDERR.puts "fetching: #{ca_issuer_url}"
    response = get_response(ca_issuer_url)
    p7c = OpenSSL::PKCS7.new(response.body)
    p7c.certificates.each do |issuing_x509_certificate|
      issuing_cert = Certificate.new(issuing_x509_certificate)
      return issuing_cert if issuing_cert.key_id == ca_id
    end
    nil
  end

  def get_response(url)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 10 # seconds

    http.request_get(url.path)
  end
end
