class IdentityConfig
  class << self
    attr_reader :store
  end

  CONVERTERS = {
    string: proc { |value| value.to_s },
    comma_separated_string_list: proc do |value|
      value.split(',')
    end,
    integer: proc do |value|
      Integer(value)
    end,
    json: proc do |value, options: {}|
      JSON.parse(value, symbolize_names: options[:symbolize_names])
    end,
    boolean: proc do |value|
      case value
      when 'true', true
        true
      when 'false', false
        false
      else
        raise 'invalid boolean value'
      end
    end,
  }

  def initialize(read_env)
    @read_env = read_env
    @written_env = {}
  end

  def add(key, type: :string, is_sensitive: false, options: {})
    value = @read_env[key]
    raise "#{key} is required but is not present" if value.nil?
    converted_value = CONVERTERS.fetch(type).call(value, options: options)
    raise "#{key} is required but is not present" if converted_value.nil?

    @written_env[key] = converted_value
    @written_env
  end

  def self.build_store(config_map)
    config = IdentityConfig.new(config_map)
    config.add(:aws_http_timeout, type: :integer)
    config.add(:aws_region)
    config.add(:ca_issuer_host_allow_list, type: :comma_separated_string_list)
    config.add(:certificate_store_directory)
    config.add(:client_cert_escaped, type: :boolean)
    config.add(:client_cert_logger_s3_bucket_name)
    config.add(:database_host)
    config.add(:database_name)
    config.add(:database_password)
    config.add(:database_statement_timeout, type: :integer)
    config.add(:database_timeout, type: :integer)
    config.add(:database_username)
    config.add(:dod_root_identifiers, type: :comma_separated_string_list)
    config.add(:domain_name)
    config.add(:openssl_verify_enabled, type: :boolean)
    config.add(:ficam_certificate_bundle_file, type: :string)
    config.add(:http_open_timeout, type: :integer)
    config.add(:http_read_timeout, type: :integer)
    config.add(:identity_idp_host)
    config.add(:login_certificate_bundle_file, type: :string)
    config.add(:newrelic_license_key)
    config.add(:nonce_bloom_filter_enabled, type: :boolean)
    config.add(:nonce_bloom_filter_hash_count, type: :integer)
    config.add(:nonce_bloom_filter_prefix)
    config.add(:nonce_bloom_filter_server)
    config.add(:nonce_bloom_filter_size, type: :integer)
    config.add(:nonce_bloom_filter_ttl, type: :integer)
    config.add(:required_policies, type: :json)
    config.add(:piv_cac_verify_token_secret)
    config.add(:secret_key_base)
    config.add(:token_encryption_key_pepper)
    config.add(:token_encryption_key_salt)
    config.add(:token_encryption_key_pepper_old)
    config.add(:token_encryption_key_salt_old)
    final_env = config.add(:trusted_ca_root_identifiers, type: :comma_separated_string_list)

    @store = RedactedStruct.new('IdentityConfig', *final_env.keys, keyword_init: true).
      new(**final_env)
  end
end
