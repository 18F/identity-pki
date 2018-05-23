class TokenService
  include Singleton

  TOKEN_LIFESPAN = 5.minutes
  RANDOM_BYTES = 8

  class << self
    delegate :box, to: :instance

    delegate :open, to: :instance
  end

  # :reek:DuplicateMethodCall
  def box(data)
    # The RANDOM_BYTES are there to introduce some entropy since we aren't putting a lot
    # of information into the token. Ruby hashes serialize in the order the keys are
    # introduced, so the data is sandwiched between two random strings, though that is
    # sandwiched in non-random strings -- namely, `{` and `}` to open/close the JSON object.
    message_encryptor.encrypt_and_sign(
      { r1: SecureRandom.base64(RANDOM_BYTES) }.
      merge(data).
      merge(
        r2: SecureRandom.base64(RANDOM_BYTES)
      ).to_json,
      expires_in: TOKEN_LIFESPAN
    )
  end

  def open(crypt)
    data = JSON.parse(message_encryptor.decrypt_and_verify(crypt))
    data.except('r1', 'r2')
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    {
      'error' => 'token.invalid',
    }
  end

  private

  def message_encryptor
    @message_encryptor ||= begin
      encryptor = ActiveSupport::MessageEncryptor.new(current_key, cipher: 'aes-256-gcm')
      prior_keys.each { |key| encryptor.rotate key }
      encryptor
    end
  end

  def current_key
    salt, pepper = key_salt_and_pepper
    ActiveSupport::KeyGenerator.new(pepper).generate_key(salt)
  end

  def prior_keys
    prior_key_signifiers.map do |ending|
      old_salt, old_pepper = key_salt_and_pepper(ending)
      ActiveSupport::KeyGenerator.new(old_pepper).generate_key(old_salt)
    end
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
