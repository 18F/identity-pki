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

  def select_certificates(s3_client, continuation_token = nil, certs = [], &block)
    loop do
      resp = fetch_object_list(s3_client, continuation_token)
      certs |= process_certificates_in_response(s3_client, resp, &block)

      continuation_token = resp.next_continuation_token
      return certs.compact unless continuation_token
    end
  end

  def process_unknown_cert(x509_cert, chain = [])
    begin
      walk_certificate_chain(x509_cert) do |issuing_cert|
        chain << issuing_cert
      end
    rescue StandardError => e
      puts e.message
      puts "------------------------------"
    end

    summarize_chain(chain)
    chain
  end

  def output_certs(certs)
    puts certs.select(&:valid?).map(&:to_pem).join("\n\n")
  end

  # start with the *.p7c pointed to by the URL and follow the chain of certs
  # until we either find one we have in our issuer list or we get to a self-signed
  # cert.
  # return all the certs that make up the chain
  def walk_certificate_chain(leaf_cert, &block)
    process_tree([leaf_cert]) do |cert|
      raw_p7c = get_cert_issuer(cert)
      process_p7c(OpenSSL::PKCS7.new(raw_p7c), &block) if raw_p7c.present?
    end
  end

  def summarize_chain(chain)
    count = chain.count
    puts "  found #{count} #{'cert'.pluralize(count)}\n\n"
  end

  def fetch_object_list(s3_client, continuation_token)
    s3_client.list_objects_v2(
      bucket: ENV['AWS_CERT_LOG_BUCKET'], max_keys: 200,
      continuation_token: continuation_token
    )
  end

  def process_certificates_in_response(s3_client, response, &block)
    response.contents.map { |meta| process_certificate(s3_client, meta) }.select(&block)
  end

  def process_certificate(s3_client, object_meta)
    object_resp = s3_client.get_object(
      bucket: ENV['AWS_CERT_LOG_BUCKET'], key: object_meta.key
    )
    Certificate.new(OpenSSL::X509::Certificate.new(object_resp.body.read))
  end

  def process_tree(stack, chain = [])
    while stack.any?
      new_certs = yield stack.shift
      chain |= new_certs if new_certs != nil
      stack |= new_certs if new_certs != nil
    end
    chain
  end

  def process_p7c(p7c, next_certs = [])
    p7c.certificates.each do |issuing_x509_certificate|
      issuing_cert = Certificate.new(issuing_x509_certificate)

      yield issuing_cert

      next_certs << issuing_cert if issuing_cert.validate_untrusted_root == 'unverified'
    end
    next_certs
  end

  def get_cert_issuer(cert)
    ca_issuer_url = cert.issuer_metadata[:ca_issuer_url]

    response = get_response(ca_issuer_url)
    case response
    when Net::HTTPSuccess then
      response.body
    else
      warn "  unable to fetch <#{ca_issuer_url}>: #{response.message}"
    end
  end

  def get_response(url)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 10 # seconds

    http.request_get(url.path)
  end
end
