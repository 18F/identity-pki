# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'yaml'

require 'aws-sdk-lambda'
require 'aws-sdk-secretsmanager'
require 'aws-sdk-sts'
require 'rest-client'
require 'subprocess'

module Cloudlib
  # Class for handling AWS Lambda function deployment.
  class Lambda
    attr_reader :source_config

    CloudlibSourceConfigName = '.cloudlib-source.yaml'
    CloudlibYamlName = 'cloudlib.yaml'

    def initialize
      log.debug('#initialize')
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

    def cmd_init
      log.info('init command starting')
      populate_repo_info

      begin
        clone_url = source_config.fetch('repo_clone_url')
        path_to_yaml = source_config.fetch('path_to_cloudlib_yaml')
      rescue KeyError
        log.error("Couldn't find required key in " + CloudlibSourceConfigName)
        raise
      end

      init_config_dir
      checkout_dir = clone_cloudlib_repo(clone_url: clone_url)
      link_cloudlib_config(checkout_dir: checkout_dir,
                           path_to_yaml: path_to_yaml)

      log.info('init complete')
    end

    def cmd_info(name)
      raise NotImplementedError.new(name) # TODO
    end

    def cmd_list
      lambda_data = cloudlib_yaml_data.fetch('lambdas')
      puts 'Known lambdas:'
      puts '- ' + lambda_data.keys.join("\n- ")
    end

    # List available environments for the given lambda
    #
    # @param [String] lambda_name
    #
    # @return [Array<String>]
    def get_available_envs(lambda_name: name)
      l_config = config_for_lambda(name: lambda_name)
      l_config.fetch('envs')
    end

    # Deploy a new version of a lambda function to AWS.
    #
    # @param [String] name The cloudlib name of the lambda
    # @param [String] env The target deploy environment
    # @param [String, nil] region The target region (inferred from AWS config
    #   by default)
    # @param [String, nil] git_rev The git revision to deploy (defaults to
    #   parsing currently checked out HEAD)
    #
    # @return [Seahorse::Client::Response] Response from update_function_code
    #
    def deploy_lambda(name:, env:, region: nil, git_rev: nil)
      l_config = config_for_lambda(name: name)
      env_config = config_for_env(name: env)

      git_rev ||= 'HEAD'
      git_rev = git_rev_parse(git_rev)

      log.info("Deploying #{name.inspect} to #{env.inspect} @ #{git_rev}")

      aws_account = env_config.fetch('aws_account').to_s
      aws_profile = env_config.fetch('aws_profile')
      log.debug("env_config: #{env_config.inspect}")
      ENV['AWS_PROFILE'] = aws_profile

      assert_account_id(expected_id: aws_account)

      aws_lambda = Aws::Lambda::Client.new

      region ||= aws_lambda.config.region

      is_per_vpc = l_config.fetch('per_vpc')
      if is_per_vpc
        function_name = env + '-' + name
      else
        function_name = name
      end

      s3_bucket = interpolate_s3_bucket(
        lambda_config: l_config, account_id: aws_account, region: region
      )
      s3_key = render_s3_prefix(lambda_config: l_config, git_rev: git_rev)

      params = {
        function_name: function_name,
        publish: true,
        s3_bucket: s3_bucket,
        s3_key: s3_key,
      }
      log.info('aws lambda update-function-code ' + params.inspect)
      resp = aws_lambda.update_function_code(params)
      log.info('Deployed as revision ' + resp.revision_id)

      send_slack_webhook(
        lambda_name: function_name, env: env, region: region, git_rev: git_rev,
        s3_bucket: s3_bucket, s3_key: s3_key, update_code_response: resp
      )

      resp
    end

    # Send a deploy notification webhook to Slack.
    #
    # Look up the webhook URL from AWS Secrets Manager using the
    # slack_webhook_secret_id listed in the cloudlib.yaml file.
    #
    # You can debug what different formatting options will look like at
    # https://api.slack.com/docs/messages/builder
    #
    def send_slack_webhook(lambda_name:, env:, region:, s3_bucket:, s3_key:,
                           git_rev:, update_code_response:)
      secret_id = cloudlib_yaml_data.fetch('slack_webhook_secret_id')
      unless secret_id
        log.debug('slack_webhook_secret_id is disabled')
        return
      end

      log.debug('Looking up Slack webhook URL from ' + secret_id.inspect)
      smc = Aws::SecretsManager::Client.new
      hook_url = smc.get_secret_value(secret_id: secret_id).secret_string

      # construct payload

      # obviously this is not for security audit trail
      username = ENV['GSA_USERNAME'] || ENV['USER'] || Etc.getlogin

      git_branch = git_name_rev(git_rev)
      if git_branch.empty?
        git_branch = git_rev[0..8]
      end

      # link to AWS console
      lambda_href = "https://#{region}.console.aws.amazon.com/lambda/home" \
        "?region=#{region}#/functions/#{lambda_name}?tab=monitoring"
      l_link = "<#{lambda_href}|#{lambda_name}>"

      msg = "lambda *#{l_link}* deployed to *#{env}* by #{username}"

      # slack formatted deploy date
      deploy_time = update_code_response.last_modified
      deploy_time_message = "<!date^#{deploy_time.strftime('%s')}" + \
                            "^{date_num} {time}|#{deploy_time}>"

      # github link to commit
      repo_url = cloudlib_yaml_data.fetch('repo_github_url')
      commit_url = repo_url.gsub(%r{/\z}, '') + '/commit/' + git_rev

      s3_url = 's3://' + s3_bucket + '/' + s3_key

      fields = {
        'Environment' => env,
        'Branch' => git_branch,
        'Deployer' => username,
        'Time' => deploy_time_message,
        'Version' => {
          'value' => update_code_response.revision_id, 'short' => false,
        },
        'Commit' => "<#{commit_url}|#{git_rev[0..8]}>",
        'Code Bundle S3 URL' =>
            "<#{s3_url}|#{s3_url[0..13]}...#{s3_url[-12..-1]}>",
      }

      payload = {
        username: 'Cloudlib lambda deploy',
        icon_emoji: ':rocket:',
        attachments: [
          {
            color: 'good',
            mrkdwn_in: ['text', 'pretext'],
            pretext: msg,
            fallback: "#{lambda_name} deployed to #{env} by #{username}",
            fields: fields.map { |key, val|
              if val.is_a?(Hash)
                {
                  title: key,
                  value: val.fetch('value'),
                  short: val.fetch('short'),
                }
              else
                {
                  title: key,
                  value: val,
                  short: true,
                }
              end
            },
          },
        ],
      }

      # Uncomment for payload debugging
      # log.debug(JSON.pretty_generate(payload))

      log.info('Sending slack webhook')
      RestClient.post(hook_url, JSON.dump(payload),
                      content_type: 'Application/JSON')
    end

    def repo_root
      return @repo_root if @repo_root

      populate_repo_info

      @repo_root
    end

    def cloudlib_yaml_path
      File.join(repo_root, CloudlibYamlName)
    end

    def cloudlib_yaml_data
      @cloudlib_yaml_data ||= cloudlib_yaml_data!
    end

    def cloudlib_yaml_data!
      log.debug("Loading main config from #{cloudlib_yaml_path.inspect}")
      YAML.safe_load(File.read(cloudlib_yaml_path), aliases: true)
    end

    # @return [Hash]
    def config_for_lambda(name:)
      lambdas = cloudlib_yaml_data.fetch('lambdas')
      begin
        return lambdas.fetch(name)
      rescue KeyError
        raise NotFound.new(
          "No lambda named #{name.inspect} found in #{CloudlibYamlName}"
        )
      end
    end

    # @return [Hash]
    def config_for_env(name:)
      envs = cloudlib_yaml_data.fetch('environments')
      begin
        return envs.fetch(name)
      rescue KeyError
        raise NotFound.new(
          "No environment named #{name.inspect} found in #{CloudlibYamlName}"
        )
      end
    end

    # Get s3_bucket from lambda_config hash and replace <account-id> and
    # <region> values.
    #
    # @param [Hash] lambda_config
    # @param [String] account_id
    # @param [String] region
    #
    # @return [String]
    def interpolate_s3_bucket(lambda_config:, account_id:, region:)
      lambda_config.fetch('s3_bucket')
                   .gsub('<account-id>', account_id)
                   .gsub('<region>', region)
    end

    # @param [Hash] lambda_config
    # @param [String] git_rev
    def render_s3_prefix(lambda_config:, git_rev:)
      lambda_config.fetch('s3_prefix') + git_rev + '.zip'
    end

    # Create directory ~/.config/cloudlib if it doesn't already exist.
    def init_config_dir
      return if File.directory?(config_dir)

      log.info('+ mkdir -p ' + config_dir)
      FileUtils.mkdir_p(config_dir)
    end

    # Path to ~/.config/cloudlib where config repos are checked out
    def config_dir
      File.expand_path('~/.config/cloudlib')
    end

    # Git clone {clone_url} under {#config_dir}
    #
    # @param [String] clone_url
    # @return [String] The file path to the resulting checkout directory
    #
    def clone_cloudlib_repo(clone_url:)
      target_dir = File.join(config_dir,
                             File.basename(clone_url.gsub(/\.git\z/, '')))
      log.info("Cloning #{clone_url.inspect} into #{target_dir.inspect}")

      cmd = %W[git clone #{clone_url} #{target_dir}]
      log.debug('+ ' + cmd.join(' '))
      Subprocess.check_call(cmd)
      log.debug('finished clone')

      target_dir
    end

    # Create a symlink pointing from cloudlib.yaml under the repo root to the
    # specified {path_to_yaml} in the given checkout directory.
    def link_cloudlib_config(checkout_dir:, path_to_yaml:)
      target = File.join(checkout_dir, path_to_yaml)

      # make sure target exists and is a YAML file
      begin
        YAML.safe_load(File.read(target), aliases: true)
      rescue StandardError
        log.error('Refusing to create symlink due to error')
        raise
      end

      source = File.join(repo_root, CloudlibYamlName)

      log.info("Creating symlink from #{source.inspect} => #{target.inspect}")

      File.symlink(target, source)
    end

    # Follow the symlink at cloudlib.yaml to find the cloudlib config repo,
    # then run `git pull --ff-only` inside that repo.
    def update_cloudlib_config
      # TODO
      raise NotImplementedError.new
    end

    # Wrapper around git rev-parse HEAD
    # @return [String]
    def git_rev_parse_head
      cmd = %w[git rev-parse HEAD]
      log.debug('+ ' + cmd.join(' '))
      Subprocess.check_output(cmd).chomp
    end

    # Wrapper around git rev-parse --verify
    # @param [String] ref
    # @return [String]
    def git_rev_parse(ref)
      if ref.start_with?('-')
        raise ArgumentError.new('Ref cannot start with -')
      end
      cmd = %W[git rev-parse --verify #{ref} --]
      log.debug('+ ' + cmd.join(' '))
      Subprocess.check_output(cmd).chomp
    end

    # Get the human-readable ref name of ref. If it can't be parsed, return the
    # original ref unchanged.
    #
    # Wrapper around git name-rev.
    #
    # @param [String] ref A gitref
    # @return [String]
    #
    def git_name_rev(ref)
      cmd = %W[git name-rev --name-only #{ref}]
      log.debug('+ ' + cmd.join(' '))
      result = Subprocess.check_output(cmd).chomp

      if result.start_with?('Could not get sha1')
        return ref
      end

      result
    end

    private

    def assert_account_id(expected_id:)
      actual = Aws::STS::Client.new.get_caller_identity.account
      if actual == expected_id
        return true
      end

      log.error('Mismatch between expected and actual AWS account IDs')
      log.error('Is something wrong with your ~/.aws/credentials ?')
      log.error("Expected account ID: #{expected_id.inspect}")
      log.error("Actual account ID:   #{actual.inspect}")
      raise Cloudlib::CLIError.new(
        "Mismatch between expected #{expected_id.inspect} and actual " \
        "#{actual.inspect} AWS account ID"
      )
    end

    # Find the git repository containing the current working directory.
    # Locate the top-level cloudlib config files.
    #
    # Populate information in instance variables to store these details.
    def populate_repo_info
      log.debug('#populate_repo_info')

      cmd = %w[git rev-parse --show-toplevel]
      log.debug('+ ' + cmd.join(' '))
      begin
        @repo_root = Subprocess.check_output(cmd).chomp
      rescue Subprocess::NonZeroExit
        log.error('Current directory is not inside a git repo')
        @repo_root = nil
      end

      cl_source_path = File.join(@repo_root || '.', CloudlibSourceConfigName)
      log.debug("Loading source config from #{cl_source_path.inspect}")
      begin
        @source_config = YAML.safe_load(File.read(cl_source_path),
                                        aliases: true)
      rescue Errno::ENOENT
        log.error('Could not find Cloudlib source config at ' +
                  cl_source_path.inspect)
        raise NotInRepository.new('Not in Cloudlib lambda repo. ENOENT: ' +
                                  cl_source_path.inspect)
      end
    end
  end
end
