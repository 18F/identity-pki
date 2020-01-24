class TokenService
  TOKEN_LIFESPAN = 5.minutes
  RANDOM_BYTES = 8

  class << self
    # :reek:DuplicateMethodCall
    def box(data)
      # The RANDOM_BYTES are there to introduce some entropy since we aren't putting a lot
      # of information into the token. Ruby hashes serialize in the order the keys are
      # introduced, so the data is sandwiched between two random strings, though that is
      # sandwiched in non-random strings -- namely, `{` and `}` to open/close the JSON object.
      message_encryptor.encrypt_and_sign(
        { r1: SecureRandom.base64(RANDOM_BYTES) }.
        merge(data).
        merge(r2: SecureRandom.base64(RANDOM_BYTES)).to_json,
        expires_in: TOKEN_LIFESPAN
      )
    end

    def open(crypt, hmac_header = '')
      data = JSON.parse(message_encryptor.decrypt_and_verify(crypt))
      if authentic?(crypt, hmac_header)
        data.except('r1', 'r2')
      else
        { 'error' => 'auth.required' }
      end
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      { 'error' => 'token.invalid' }
    end

    private

    # :reek:ControlParameter - controlled by hmac_header
    def authentic?(token, hmac_header)
      secret = Figaro.env.piv_cac_verify_token_secret
      # TODO: once everything is deployed and configured and working, we'll
      # switch to requiring the secret be configured
      # return true if secret.blank?

      # `hmac #{user}:#{nonce}:#{digest}`
      nonce, hmac = (hmac_header&.split(/:/, 3) || [])[1..2]

      secret.blank? || hmac_header&.start_with?('hmac ') && !nonce_seen?(nonce) &&
        hmac == build_hmac(secret, token, nonce)
    end

    # :reek:UtilityFunction
    def build_hmac(secret, token, nonce)
      Base64.urlsafe_encode64(OpenSSL::HMAC.digest('SHA256', secret, [token, nonce].join('+')))
    end

    def nonce_seen?(nonce)
      return false unless FeatureManagement.nonce_bloom_filter_enabled?
      return true if bloom_filter.include?(nonce)
      bloom_filter.insert(nonce)
      false
    end

    def bloom_filter
      @bloom_filter ||= begin
        BloomFilter::CountingRedis.new(
          bloom_filter_spec.merge(bloom_filter_server).merge(
            type: :redis,
            server: bloom_filter_server
          )
        )
      end
    end

    # :reek:UtilityFunction
    def bloom_filter_spec
      env = Figaro.env
      size = (env.nonce_bloom_filter_size || 100_000).to_i
      { identifier: env.nonce_bloom_filter_prefix || 'nonce',
        ttl: env.nonce_bloom_filter_ttl || TOKEN_LIFESPAN,
        hashes: env.nonce_bloom_filter_hash_count || 4,
        size: size,
        seed: 123_456_789 }
    end

    # :reek:UtilityFunction
    def bloom_filter_server
      { url: Figaro.env.nonce_bloom_filter_server || 'redis://localhost/' }
    end

    def message_encryptor
      @message_encryptor ||= begin
        encryptor = ActiveSupport::MessageEncryptor.new(current_key, cipher: 'aes-256-gcm')
        prior_keys.each { |key| encryptor.rotate key }
        encryptor
      end
    end

    def current_key
      salt, pepper = key_salt_and_pepper
      truncate_key(ActiveSupport::KeyGenerator.new(pepper).generate_key(salt))
    end

    def prior_keys
      prior_key_signifiers.map do |ending|
        old_salt, old_pepper = key_salt_and_pepper(ending)
        truncate_key(ActiveSupport::KeyGenerator.new(old_pepper).generate_key(old_salt))
      end
    end

    # Ruby 2.3's OpenSSL will truncate keys automatically
    # Newer versions raise an error with the wrong length. We have 64-byte keys
    # that we manually truncate to 32 bytes
    def truncate_key(key)
      key[0...32]
    end

    # :reek:UtilityFunction
    def key_salt_and_pepper(ordinal = nil)
      env = Figaro.env
      if ordinal
        [env.send(:"token_encryption_key_salt_#{ordinal}!"),
         env.send(:"token_encryption_key_pepper_#{ordinal}!")]
      else
        [env.token_encryption_key_salt!,
         env.token_encryption_key_pepper!]
      end
    end

    def prior_key_signifiers
      salt_endings = gather_env_key_endings('token_encryption_key_salt_')
      pepper_endings = gather_env_key_endings('token_encryption_key_pepper_')
      (salt_endings & pepper_endings).sort_by(&:to_i)
    end

    # :reek:UtilityFunction
    def gather_env_key_endings(prefix)
      range = prefix.length..-1
      ENV.
        keys.
        select { |name| name.start_with?(prefix) }.
        map { |name| name[range] }
    end
  end
end
