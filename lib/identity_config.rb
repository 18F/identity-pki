module IdentityConfig
  def self.store
    Identity::Hostdata.config
  end

  CONFIG_BUILDER = proc do |config|
    config.add(:aws_http_timeout, type: :integer)
    config.add(:aws_region)
    config.add(:ca_issuer_host_allow_list, type: :comma_separated_string_list)
    config.add(:certificate_store_directory)
    config.add(:client_cert_escaped, type: :boolean)
    config.add(:client_cert_logger_s3_bucket_name, type: :string)
    config.add(:database_host, type: :string)
    config.add(:database_name, type: :string)
    config.add(:database_password, type: :string)
    config.add(:database_sslmode, type: :string)
    config.add(:database_statement_timeout, type: :integer)
    config.add(:database_timeout, type: :integer)
    config.add(:database_username, type: :string)
    config.add(:domain_name, type: :string)
    config.add(:openssl_verify_enabled, type: :boolean)
    config.add(:ficam_certificate_bundle_file, type: :string)
    config.add(:http_open_timeout, type: :integer)
    config.add(:http_read_timeout, type: :integer)
    config.add(:identity_idp_host, type: :string)
    config.add(:log_to_stdout, type: :boolean)
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
    config.add(:trusted_ca_root_identifiers, type: :comma_separated_string_list)
  end.freeze
end
