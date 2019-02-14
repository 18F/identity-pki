# frozen_string_literal: true

module Cloudlib
  module Commands
    # cloudlib lambda subcommand
    class Lambda < Commands::Base
      desc 'init', 'Initialize configuration and set up symlinks'
      def init
        Cloudlib::Lambda.new.cmd_init
      end

      desc 'list', 'List known lambdas in current repo'
      def list
        Cloudlib::Lambda.new.cmd_list
      end

      desc('deploy NAME ENV',
           'Deploy current rev of NAME lambda to the ENV environment')
      method_option :revision, aliases: '-r', type: :string,
                               desc: 'Git revision to deploy'
      def deploy(name, env=nil)
        cl = Cloudlib::Lambda.new
        if env.nil?
          env_names = cl.get_available_envs(lambda_name: name)
          raise Thor::Error.new('Must pass ENV, one of: ' + env_names.inspect)
        end

        cl.deploy_lambda(name: name, env: env, git_rev: options['revision'])
      end

      desc 'info NAME', 'Show information about the NAME lambda'
      def info(name)
        raise NotImplementedError.new(name)
      end
    end
  end
end
