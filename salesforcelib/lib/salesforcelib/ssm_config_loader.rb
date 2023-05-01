require 'aws-sdk-ssm'

module Salesforcelib
  # We store the shared OAuth app credentials in SSM Parameters
  # This class helps load them
  class SsmConfigLoader
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
      Config.new(
        client_id: load_value('/account/salesforce/client_id'),
        client_secret: load_value('/account/salesforce/client_secret'),
        instance_url: load_value('/account/salesforce/instance_url'),
      )
    end

    def load_value(name)
      ssm_client.get_parameter(
        name: name,
        with_decryption: true,
      ).parameter.value.chomp
    end

    def ssm_client
      @ssm_client ||= Aws::SSM::Client.new(
        http_idle_timeout: 3,
        http_open_timeout: 3,
        http_read_timeout: 3,
      )
    end
  end
end
