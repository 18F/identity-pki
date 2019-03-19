require 'active_support/core_ext/hash/deep_merge'
require 'logger'
require 'login_gov/hostdata'
require 'yaml'

module Deploy
  class Activate
    attr_reader :logger, :s3_client

    def initialize(logger: default_logger, s3_client: nil)
      @logger = logger
      @s3_client = s3_client
    end

    def run
      LoginGov::Hostdata.s3(logger: logger, s3_client: s3_client).download_configs(
        '/%<env>s/pivcac/v1/application.yml' => env_yaml_path
      )

      File.open(result_yaml_path, 'w') { |file| file.puts YAML.dump(application_config) }

      FileUtils.chmod(0o640, [env_yaml_path, result_yaml_path])

      download_extra_certs_from_s3
    end

    private

    def download_extra_certs_from_s3
      ec2_data = LoginGov::Hostdata::EC2.load
      aws_region = ec2_data.region
      aws_account_id = ec2_data.account_id

      begin
        LoginGov::Hostdata::S3.new(
          bucket: "login-gov.secrets.#{aws_account_id}-#{aws_region}",
          env: env,
          region: aws_region,
          logger: logger,
          s3_client: s3_client,
        ).download_configs('/%<env>s/extra_pivcac_certs.pem' => 'config/certs/extra_pivcac_certs.pem')
      rescue Aws::S3::Errors::NotFound; end
    end

    def default_logger
      logger = Logger.new(STDOUT)
      logger.progname = 'deploy/activate'
      logger
    end

    def env_yaml_path
      File.join(root, 'config/application_s3_env.yml')
    end

    def root
      File.expand_path('../../../', __FILE__)
    end

    def application_config
      YAML.load_file(example_application_yaml_path).deep_merge(YAML.load_file(env_yaml_path))
    end

    def example_application_yaml_path
      File.join(root, 'config/application.yml.example')
    end

    def result_yaml_path
      File.join(root, 'config/application.yml')
    end
  end
end
