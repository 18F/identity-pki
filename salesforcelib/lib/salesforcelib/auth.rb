require 'uri'
require 'active_support/core_ext/object/to_query'
require 'faraday'
require 'restforce'
require 'salesforcelib/server'
require 'salesforcelib/ssm_config_loader'
require 'salesforcelib/keychain_config'

module Salesforcelib
  class Auth
    attr_reader :ssm_config, :keychain_config

    # @param [Salesforcelib::SsmConfigLoader::Config] ssm_config
    # @param [Salesforcelib::KeychainConfig] keychain_config
    def initialize(ssm_config: Salesforcelib::SsmConfigLoader.load!, keychain_config: nil, verbose: false)
      @ssm_config = ssm_config
      @keychain_config = keychain_config || Salesforcelib::KeychainConfig.new(ssm_config.instance_url)
      @verbose = verbose
    end

    def verbose?
      !!@verbose
    end

    # Authenticates to Salesforce and returns a Restforce client
    # Loads tokens from keychain if they exist, kicks off an OAuth token exchange
    # if they do not
    # @return [Restforce]
    def auth!
      tokens = if keychain_config.has_tokens?
        keychain_config
      else
        system('open', '-n', authorize_url)
        code = Salesforcelib::Server.wait_for_callback!

        load_token(code).tap do |response|
          keychain_config.update!(
            access_token: response.access_token,
            refresh_token: response.refresh_token,
          )
        end
      end

      Restforce.new(
        oauth_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        instance_url: ssm_config.instance_url,
        client_id: ssm_config.client_id,
        client_secret: ssm_config.client_secret,
        api_version: '57.0',
        authentication_callback: proc do |response|
          keychain_config.update!(
            access_token: response.access_token,
            refresh_token: response.refresh_token,
          )
        end,
      ) do |builder|
        builder.response :logger if verbose?
      end.tap do |restforce|
        # run a test query to force authentication
        restforce.query('SELECT Id FROM Case LIMIT 1')
      end
    rescue Restforce::AuthenticationError => err
      if err.message.include?('expired access/refresh token')
        keychain_config.clear!
        retry
      else
        raise err
      end
    end

    def authorize_url
      URI.join(ssm_config.instance_url, '/services/oauth2/authorize').tap do |uri|
        uri.query = {
          response_type: 'code',
          client_id: ssm_config.client_id,
          redirect_uri: Salesforcelib::Server.redirect_uri,
        }.to_query
      end.to_s
    end

    TokenResponse = Struct.new(
      :access_token,
      :refresh_token,
      :issued_at,
      :instance_url,
      keyword_init: true,
    )

    # @return [TokenResponse]
    def load_token(code)
      response = Faraday.new.post(URI.join(ssm_config.instance_url, '/services/oauth2/token')) do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(
          client_id: ssm_config.client_id,
          client_secret: ssm_config.client_secret,
          grant_type: 'authorization_code',
          redirect_uri: Salesforcelib::Server.redirect_uri,
          code: code,
        )
      end

      values = JSON.parse(response.body)

      TokenResponse.new(
        access_token: values['access_token'],
        refresh_token: values['refresh_token'],
        instance_url: values['instance_url'],
        issued_at: values['issued_at'],
      )
    end
  end
end
