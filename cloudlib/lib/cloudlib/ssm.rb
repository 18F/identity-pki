# frozen_string_literal: true

require 'subprocess'
require 'active_support'
require 'active_support/json'
require 'ruby-progressbar'

module Cloudlib
  module SSM

    class SSMError < Cloudlib::Error; end

    def self.ec2lib_for_vpc(vpc_id)
      # mapping from vpc_id => Cloudlib::EC2 object
      @ec2libs ||= {}

      @ec2libs[vpc_id] ||= Cloudlib::EC2.new_from_vpc_id(vpc_id)
    end

    # This class is a helper to manage opening a SSM session to a single
    # server. It accepts an instance ID or Aws::EC2::Instance object, and
    # provides helper methods to faciliate opening a SSM session to that
    # instance.
    class Single

      attr_reader :cl, :instance, :document, :ssm_env, :parameters

      # @param [String] instance_id
      # @param [Aws::EC2::Instance] instance
      # @param [String] document
      # @param [String] doc_env
      # @param [Hash,nil] parameters
      def initialize(instance_id: nil, instance: nil, document: nil, doc_env: nil, parameters: nil, cli_timeout: 60)
        @document = document
        @parameters = parameters
        @cli_timeout = cli_timeout

        if (instance_id && instance) || (!instance_id && !instance)
          raise ArgumentError.new('must pass one of instance_id or instance')
        end

        @ec2 = Cloudlib::EC2.new_resource

        if instance_id
          instance = @ec2.instance(instance_id)
        end

        @instance = instance

        if instance.state.name != 'running'
          msg = "Instance #{instance.instance_id} is in state " +
                instance.state.name.inspect
          log.error(msg)
          raise SSMError.new(msg)
        end

        @cl = SSM.ec2lib_for_vpc(@instance.vpc_id)

        if doc_env
          @ssm_env = doc_env
        else
          @ssm_env = @cl.env
        end

      end

      def log
        @log ||= Cloudlib.class_log(self.class, STDERR)
      end

      def instance_label
        cl.instance_label(instance)
      end

      # Runs aws ssm start-session against instance.instance_id w/provided document
      #
      # @return DOES NOT RETURN
      def ssm_session_exec
        cmd = [
          'aws',
          'ssm',
          'start-session',
          '--target', instance.instance_id,
          '--document', "#{@ssm_env}-ssm-document-#{@document}",
          '--cli-read-timeout', @cli_timeout.to_s,
          '--cli-connect-timeout', @cli_timeout.to_s,
        ]
        cmd += ['--parameters', parameters.to_json] if parameters
        log.debug('exec: ' + cmd.inspect)
        exec(*cmd)
      end

      # Runs SSM command, waits for it synchronously
      # Future work: maybe an async option?
      # @param show_progress_bar [Boolean] prints a progress bar to STDERR while waiting
      # @param raise_on_failure [Boolean] when true, throws on errors. when false, returns failure result
      # @return [Aws::SSM::Types::GetCommandInvocationResult]
      def ssm_send_command(show_progress_bar: false, raise_on_failure: true)
        ssm_client = Aws::SSM::Client.new

        document_name = "#{@ssm_env}-ssm-cmd-#{@document}"

        cmd = [
          'aws',
          'ssm',
          'send-command',
          '--targets', "Key=InstanceIds,Values=#{instance.instance_id}",
          '--document-name', document_name,
        ]
        cmd += ['--parameters', parameters.to_json] if parameters
        log.info(cmd.join(' '))

        command = ssm_client.send_command(
          document_name: document_name,
          targets: [
            { key: 'InstanceIds', values: [instance.instance_id] },
          ],
          parameters: parameters,
        )

        log.debug('send_command result: ' + command.to_s)

        if show_progress_bar
          bar = ProgressBar.create(
            title: 'Running command',
            total: nil,
            format: '[ %t ] %B %a',
            output: STDERR,
          )
          thread = Thread.new do
            loop do
              sleep 0.1
              bar.increment
            end
          end
        end

        command_result = if raise_on_failure
          ssm_client.wait_until(
            :command_executed,
            command_id: command.command.command_id,
            instance_id: instance.instance_id,
          )
        else
          loop do
            sleep 1
            intermediate_result = ssm_client.get_command_invocation(
              command_id: command.command.command_id,
              instance_id: instance.instance_id,
            )
            break intermediate_result if %w[Success Cancelled TimedOut Failed].include?(intermediate_result.status)
          end
        end

        log.debug('command result: ' + command_result.to_s)

        command_result
      ensure
        thread&.kill
        bar&.stop
      end
    end
  end
end
