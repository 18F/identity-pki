# frozen_string_literal: true

require 'subprocess'
require 'active_support/json'

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

      attr_reader :cl, :instance, :document, :parameters

      # @param [String] instance_id
      # @param [Aws::EC2::Instance] instance
      # @param [String] document
      # @param [Hash,nil] parameters
      def initialize(instance_id: nil, instance: nil, document: nil, parameters: nil)
        @document = document
        @parameters = parameters

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
          '--document', "#{@cl.env}-ssm-document-#{@document}",
        ]
        cmd += ['--parameters', parameters.to_json] if parameters
        log.debug('exec: ' + cmd.inspect)
        exec(*cmd)
      end

      # Runs SSM command, waits for it synchronously
      # Future work: maybe an async option?
      # @return [Aws::SSM::Types::GetCommandInvocationResult]
      def ssm_send_command
        ssm_client = Aws::SSM::Client.new

        document_name = "#{@cl.env}-ssm-cmd-#{@document}"

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

        command_result = ssm_client.wait_until(
          :command_executed,
          command_id: command.command.command_id,
          instance_id: instance.instance_id
        )

        log.debug('command result: ' + command_result.to_s)

        command_result
      end
    end
  end
end
