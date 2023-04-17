require 'aws-sdk-s3'
require 'aws-sdk-sts'

module Salesforcelib
  # We store the shared OAuth app credentials in the secrets bucket in S3
  # The credentials are stored at the top level of the bucket as text files
  # This class helps parse and load them from S3
  class S3ConfigLoader
    Config = Struct.new(
      :client_id, # sometimes referred to as consumer_key
      :client_secret, # sometimes referred to as consumer_secret
      :instance_url,
      keyword_init: true,
    )

    def self.load!
      new.load!
    end

    # @return [Config]
    def load!
      # Make sure to update the README if these keys change!
      Config.new(
        client_id: load_value('salesforce_client_id'),
        client_secret: load_value('salesforce_client_secret'),
        instance_url: load_value('salesforce_instance_url'),
      )
    end

    def load_value(key)
      s3_client.get_object(
        bucket: bucket,
        key: key,
      ).body.read.chomp
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end

    def bucket
      account_id = begin
        Aws::STS::Client.new.get_caller_identity.account
      rescue
        nil
      end

      if account_id && !account_id.empty?
        "login-gov.secrets.#{account_id}-us-west-2"
      end
    end
  end
end
