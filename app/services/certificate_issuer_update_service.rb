class CertificateIssuerUpdateService
  def call
    s3_client = Aws::S3::Client.new(
      profile: ENV['AWS_PROFILE'] || 'default', region: ENV['AWS_REGION']
    )

    #fetch_issuer_list(s3_client)

    unknown_certs = enumerate_unknown_certs(s3_client)

    if unknown_certs.any?
      process_unknown_certs(unknown_certs)
    else
      puts 'No unknown issuing certs that we can process'
    end
  end

  private

  # Used by #call

  # :reek:UtilityFunction
  def fetch_issuer_list(s3_client)
    resp = s3_client.get_object(
      bucket: ENV['AWS_CERT_BUNDLE_BUCKET'], key: ENV['AWS_CERT_BUNDLE_KEY']
    )

    # clear certificate store and add what we have in the S3 bucket
    CertificateStore.instance.reset.add_pem_string(resp.body.read)
  end

  # :reek:FeatureEnvy
  def enumerate_unknown_certs(s3_client)
    select_certificates(s3_client) do |x509_cert|
      !CertificateStore.instance[x509_cert.signing_key_id] &&
        x509_cert.issuer_metadata[:ca_issuer_url].present?
    end
  end

  def process_unknown_certs(unknown_certs, new_certs = [])
    unknown_certs.each do |x509_cert|
      begin
        start_processing(x509_cert)
        new_certs |= process_unknown_cert(x509_cert)
      rescue StandardError => e
        puts e.message
        puts "------------------------------"
      end
    end
    output_certs(new_certs)
  end

  # Used by #enumerate_unknown_certs

  def select_certificates(s3_client, continuation_token = nil, certs = [], &block)
    loop do
      resp = fetch_object_list(s3_client, continuation_token)
      certs |= process_certificates_in_response(s3_client, resp, &block)

      continuation_token = resp.next_continuation_token
      return certs.compact unless continuation_token
    end
  end

  # Used by #process_unknown_certs

  # :reek:FeatureEnvy
  def start_processing(x509_cert)
    issuer_metadata = x509_cert.issuer_metadata
    puts "#{issuer_metadata[:dn]}\t#{issuer_metadata[:ca_issuer_url]}"
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
    CertificateStore.instance.add_certificates(chain)
    summarize_chain(chain)
    chain
  end

  def output_certs(certs)
    CertificateStore.instance.remove_untrusted_certificates
    puts certs.select(&:valid?).map(&:to_pem).join("\n\n")
  end

  # Used by #process_unknown_cert

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

  # Used by #select_certificates

  # :reek:UtilityFunction
  def fetch_object_list(s3_client, continuation_token)
    s3_client.list_objects_v2(
      bucket: ENV['AWS_CERT_LOG_BUCKET'], max_keys: 200,
      continuation_token: continuation_token
    )
  end

  def process_certificates_in_response(s3_client, response, &block)
    response.contents.map { |meta| process_certificate(s3_client, meta) }.select(&block)
  end

  # :reek:UtilityFunction
  def process_certificate(s3_client, object_meta)
    object_resp = s3_client.get_object(
      bucket: ENV['AWS_CERT_LOG_BUCKET'], key: object_meta.key
    )
    Certificate.new(OpenSSL::X509::Certificate.new(object_resp.body.read))
  end

  # Used by #walk_certificate_chain

  # :reek:UtilityFunction
  def process_tree(stack, chain = [])
    while stack.any?
      new_certs = yield stack.shift
      chain |= new_certs if new_certs != nil
      stack |= new_certs if new_certs != nil
    end
    chain
  end

  # :reek:UtilityFunction
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

    #puts "  fetching <#{ca_issuer_url}>"
    response = get_response(ca_issuer_url)
    case response
    when Net::HTTPSuccess then
      response.body
    else
      warn "  unable to fetch <#{ca_issuer_url}>: #{response.message}"
    end
  end

  # Used by #get_cert_issuer

  # :reek:FeatureEnvy
  def get_response(url)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 10 # seconds

    http.request_get(url.path)
  end
end
