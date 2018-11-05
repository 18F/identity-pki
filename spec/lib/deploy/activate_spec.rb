require 'rails_helper'
require 'fakefs/spec_helpers'
require 'login_gov/hostdata/fake_s3_client'
require Rails.root.join('lib', 'deploy', 'activate.rb')

TRUSTED_ROOT_COUNT = 6

describe Deploy::Activate do
  let(:config_dir) { Rails.root.join('config') }

  around(:each) do |ex|
    LoginGov::Hostdata.reset!

    @logger = Logger.new('/dev/null')

    FakeFS do
      FakeFS::FileSystem.clone(config_dir)

      ex.run
    end
  end

  let(:logger) { @logger }
  let(:s3_client) { LoginGov::Hostdata::FakeS3Client.new }
  let(:set_up_files!) {}

  let(:subject) { Deploy::Activate.new(logger: logger, s3_client: s3_client) }

  context 'in a deployed production environment' do
    before do
      stub_request(:get, 'http://169.254.169.254/2016-09-02/dynamic/instance-identity/document').
        to_return(body: {
          'region' => 'us-west-1',
          'accountId' => '12345',
        }.to_json)

      s3_client.put_object(
        bucket: 'login-gov.app-secrets.12345-us-west-1',
        key: '/int/pivcac/v1/application.yml',
        body: application_yml
      )

      FileUtils.mkdir_p('/etc/login.gov/info')
      File.open('/etc/login.gov/info/env', 'w') { |file| file.puts 'int' }
    end

    let(:application_yml) do
      <<~YAML
        production:
          secret_key_base: 'this is a secret'
      YAML
    end

    it 'downloads configs from s3' do
      subject.run

      expect(File.exist?(File.join(config_dir, 'application.yml'))).to eq(true)
    end

    it 'merges the application.yml from s3 over the application.yml.example' do
      subject.run

      combined_application_yml = YAML.load_file(File.join(config_dir, 'application.yml'))

      # top-level key from application.yml.example
      expect(combined_application_yml['trusted_ca_root_identifiers']).not_to be_empty
      # six fingerprints, each of length 59, separated by four commas
      expect(combined_application_yml['trusted_ca_root_identifiers'].length).to eq(TRUSTED_ROOT_COUNT * 59 + TRUSTED_ROOT_COUNT - 1)
      # overridden production key from s3
      expect(combined_application_yml['production']['secret_key_base']).to eq('this is a secret')
      # production key from applicaiton.yml.example, not overwritten
      expect(combined_application_yml['production']['client_cert_escaped']).to eq('true')
    end

    it 'sets the correct permissions on the YAML files' do
      subject.run

      application_yml = File.new(File.join(config_dir, 'application.yml'))
      expect(application_yml.stat.mode.to_s(8)).to eq('100640')

      application_env_yml = File.new(File.join(config_dir, 'application_s3_env.yml'))
      expect(application_env_yml.stat.mode.to_s(8)).to eq('100640')
    end

    it 'uses a default logger with a progname' do
      subject = Deploy::Activate.new(s3_client: s3_client)
      subject.run

      expect(subject.logger.progname).to eq('deploy/activate')
    end
  end

  context 'outside a deployed production environment' do
    before do
      stub_request(:get, 'http://169.254.169.254/2016-09-02/dynamic/instance-identity/document').
        to_timeout
    end

    it 'errors' do
      expect { subject.run }.to raise_error(Net::OpenTimeout)
    end
  end
end
