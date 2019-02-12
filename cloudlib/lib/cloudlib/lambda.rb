# frozen_string_literal: true

require 'fileutils'
require 'yaml'

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

    def cmd_init(args:)
      assert_empty(args)

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

    def cmd_info(args:)
      if args.length != 1
        raise Cloudlib::CLIUsageError.new('Required arguments: NAME')
      end

      name = args.fetch(0)

      raise NotImplementedError.new(name) # TODO
    end

    def cmd_list(args:)
      assert_empty(args)

      lambda_data = cloudlib_yaml_data.fetch('lambdas')
      puts 'Known lambdas:'
      puts '- ' + lambda_data.keys.join("\n- ")
    end

    def cmd_deploy(args:)
      if args.length != 2
        raise Cloudlib::CLIUsageError.new('Required arguments: NAME, ENV')
      end
      name = args.fetch(0)
      env = args.fetch(1)

      raise NotImplementedError.new(name + env) # TODO
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
      YAML.safe_load(File.read(cloudlib_yaml_path))
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
        YAML.safe_load(File.read(target))
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

    private

    def assert_empty(args)
      raise Cloudlib::CLIUsageError.new if !args.empty?
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
        @source_config = YAML.safe_load(File.read(cl_source_path))
      rescue Errno::ENOENT
        log.error('Could not find Cloudlib source config at ' +
                  cl_source_path.inspect)
        raise NotInRepository.new('Not in Cloudlib lambda repo. ENOENT: ' +
                                  cl_source_path.inspect)
      end
    end
  end
end
