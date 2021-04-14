class TokenService
  TOKEN_LIFESPAN = 5.minutes
  RANDOM_BYTES = 8

  class << self
    def box(data, encryptor = nil)
      encryptor = message_encryptor if encryptor.nil?
      # The RANDOM_BYTES are there to introduce some entropy since we aren't putting a lot
      # of information into the token. Ruby hashes serialize in the order the keys are
      # introduced, so the data is sandwiched between two random strings, though that is
      # sandwiched in non-random strings -- namely, `{` and `}` to open/close the JSON object.
      encryptor.encrypt_and_sign(
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

    def authentic?(token, hmac_header)
      secret = IdentityConfig.store.piv_cac_verify_token_secret
      # TODO: once everything is deployed and configured and working, we'll
      # switch to requiring the secret be configured
      # return true if secret.blank?

      # `hmac #{user}:#{nonce}:#{digest}`
      nonce, hmac = (hmac_header&.split(/:/, 3) || [])[1..2]

      secret.blank? || hmac_header&.start_with?('hmac ') && !nonce_seen?(nonce) &&
        hmac == build_hmac(secret, token, nonce)
    end

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

    def bloom_filter_spec
      env = IdentityConfig.store
      { identifier: env.nonce_bloom_filter_prefix,
        ttl: env.nonce_bloom_filter_ttl,
        hashes: env.nonce_bloom_filter_hash_count,
        size: env.nonce_bloom_filter_size,
        seed: 123_456_789 }
    end

    def bloom_filter_server
      { url: IdentityConfig.store.nonce_bloom_filter_server }
    end

    def message_encryptor
      return @message_encryptor if @message_encryptor

      encryptor = ActiveSupport::MessageEncryptor.new(current_key, cipher: 'aes-256-gcm')
      old_key = prior_key

      if old_key
        encryptor.rotate prior_key
      end

      @message_encryptor = encryptor
    end

    def current_key
      salt = IdentityConfig.store.token_encryption_key_salt
      pepper = IdentityConfig.store.token_encryption_key_pepper

      truncate_key(ActiveSupport::KeyGenerator.new(pepper).generate_key(salt))
    end

    def prior_key
      old_salt = IdentityConfig.store.token_encryption_key_salt_old
      old_pepper = IdentityConfig.store.token_encryption_key_pepper_old

      if old_salt.present? && old_pepper.present?
        truncate_key(ActiveSupport::KeyGenerator.new(old_pepper).generate_key(old_salt))
      end
    end

    # Ruby 2.3's OpenSSL will truncate keys automatically
    # Newer versions raise an error with the wrong length. We have 64-byte keys
    # that we manually truncate to 32 bytes
    def truncate_key(key)
      key[0...32]
    end
  end
end
