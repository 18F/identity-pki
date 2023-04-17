require 'keychain'

module Salesforcelib
  # Manages reading and writing tokens from local keychain
  class KeychainConfig
    attr_reader :instance_url

    # @param [String] instance_url ex +https://gsa-peo--pexfl3qap.sandbox.my.salesforce.com/+
    def initialize(instance_url)
      @instance_url = instance_url
    end

    def has_tokens?
      !!(access_token_item && refresh_token_item)
    end

    def access_token
      access_token_item.password
    end

    def refresh_token
      refresh_token_item.password
    end

    def clear!
      access_token_item&.delete
      refresh_token_item&.delete
      true
    end

    def update!(access_token: nil, refresh_token: nil)
      if access_token
        if (existing = access_token_item)
          existing.password = access_token
          existing.save!
        else
          Keychain.default.generic_passwords.create(
            service: instance_url,
            account: 'access_token',
            password: access_token,
          )
        end
      end

      if refresh_token
        if (existing = refresh_token_item)
          existing.password = refresh_token
          existing.save!
        else
          Keychain.default.generic_passwords.create(
            service: instance_url,
            account: 'refresh_token',
            password: refresh_token,
          )
        end
      end
    end

    # @api private
    def access_token_item
      Keychain.default.generic_passwords.where(
        service: instance_url,
        account: 'access_token',
      ).first
    end

    # @api private
    def refresh_token_item
      Keychain.default.generic_passwords.where(
        service: instance_url,
        account: 'refresh_token',
      ).first
    end
  end
end
