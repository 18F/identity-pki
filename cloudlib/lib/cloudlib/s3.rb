require 'aws-sdk-s3'
require 'aws-sdk-sts'

module Cloudlib
  module S3
    # @return [String]
    def self.load_bucket!
      account_id = begin
        Aws::STS::Client.new.get_caller_identity.account
      rescue
        nil
      end

      if !account_id || account_id.empty?
        STDERR.puts "#{basename}: could not detect bucket, check AWS_VAULT or AWS_PROFILE env vars"
        exit 1
      end

      "login-gov.app-secrets.#{account_id}-us-west-2"
    end

    # @example
    #  app_secret_path(env: 'int', app: 'idp', remote_file: 'application.yml')
    #  => "int/idp/v1/application.yml"
    def self.app_secret_path(env:, app:, remote_file:)
      "#{env}/#{app}/v1/#{remote_file}"
    end
  end
end
