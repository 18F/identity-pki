class FeatureManagement
  def self.nonce_bloom_filter_enabled?
    IdentityConfig.store.nonce_bloom_filter_enabled
  end
end
