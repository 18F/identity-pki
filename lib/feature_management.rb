class FeatureManagement
  def self.nonce_bloom_filter_enabled?
    Figaro.env.nonce_bloom_filter_enabled == 'true'
  end
end
