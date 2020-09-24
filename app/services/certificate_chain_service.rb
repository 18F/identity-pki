class CertificateChainService
  # @param [Certificate]
  def call(cert)
    process_unknown_certs(cert.signing_key_id, cert.ca_issuer_http_url)
  end

  def process_unknown_certs(ca_id, ca_issuer_url, new_certs = [])
    ca_id.upcase!
    ca_cert = get_cert_from_issuer(ca_id, ca_issuer_url)
    process_certificate_chain(ca_cert)
  end

  def process_certificate_chain(ca_cert, chain_array = [], step = 0)
    start_processing(ca_cert, step)
    chain_array << ca_cert
    issuer_key_id = ca_cert.signing_key_id
    issuer_ca_issuer_url = ca_cert.issuer_metadata[:ca_issuer_url]
    issuer_ca_cert = get_cert_from_issuer(issuer_key_id, issuer_ca_issuer_url)
    step += 1
    if step <= 6
      process_certificate_chain(issuer_ca_cert, chain_array, step)
    end
  end

  def start_processing(x509_cert, step)
    puts "///////////////////////////////////////"
    puts "///////////// [ CA Step: #{step} ] /////////////"
    puts "///////////////////////////////////////"
    puts "#{x509_cert.to_pem}"
    puts "key_id: #{x509_cert.key_id}"
    puts "signing_key_id: #{x509_cert.signing_key_id}"
    puts "ca_issuer_dn: #{x509_cert.issuer_metadata[:dn]}"
    puts "ca_issuer_url: #{x509_cert.issuer_metadata[:ca_issuer_url]}"
  end

  def get_cert_from_issuer(ca_id, ca_issuer_url)
    puts "fetching: #{ca_issuer_url}"
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
