namespace :certs do
  MAGIC_KEY_IDS = File.read('tmp/replace-certs/certs.psv').split("\n").map do |row|
    row.split('|').last
  end

  ##
  # @param cert_chain: An array of certificates where the last cert is the leaf to search
  # @return An array of arrays where each represents a path to a PIV CA
  #
  def inspect_issued_certs(cert_chain)
    leaf = cert_chain.last
    puts "Inspecting #{leaf.subject}"
    issued_certs = begin
                     IssuingCaService.fetch_ca_repository_certs_for_cert(leaf)
                   rescue SocketError => e
                     []
                   end
    result = []
    issued_certs.each do |cert|
      if cert.signing_key_id != leaf.key_id
        next
      elsif MAGIC_KEY_IDS.include?(cert.key_id)
        puts "Found one!"
        result.push(cert_chain + [cert])
      elsif cert_chain.map(&:key_id).include?(cert.key_id)
        # Prevent infinite recursion
        next
      else
        sub_chains = inspect_issued_certs(cert_chain + [cert])
        result = result + sub_chains
      end
    end
    result
  end

  task find_common_policy_certs: :environment do
    common_policy = CertificateStore.instance['F4:27:5C:A9:C3:7C:47:F4:FA:A6:A7:B0:59:97:AA:DD:35:26:17:E3']
    chains = inspect_issued_certs([common_policy])
    binding.pry
  end
end
