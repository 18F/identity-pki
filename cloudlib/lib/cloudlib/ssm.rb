# frozen_string_literal: true

require 'subprocess'

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

      attr_reader :cl
      attr_reader :instance

      # @param [String] instance_id
      # @param [Aws::EC2::Instance] instance
      def initialize(instance_id: nil, instance: nil)
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

      # Replace this process with aws ssm start-session
      #
      # @return DOES NOT RETURN
      def ssm_session_exec
        ensure_document

        cmd = [
          'aws',
          'ssm',
          'start-session',
          '--target', instance.instance_id ,
          '--parameters', { gsausername: [gsa_username] }.to_json,
          '--document', document_name,
        ]
        log.debug('exec: ' + cmd.inspect)
        exec(*cmd)
      end

      def gsa_username
        ENV['GSA_USERNAME'].tap do |str|
          raise 'missing $GSA_USERNAME' if !str || str.empty?
        end
      end

      def document_name
        "ssm-document-#{gsa_username}"
      end

      # Creates a document that can be used for an SSM session
      def ensure_document
        return if system('aws', 'ssm', 'get-document', '--name', document_name, out: '/dev/null', err: '/dev/null')

        Tempfile.create(['document', '.yaml']) do |tmp|
          tmp = OpenStruct.new(path: '/tmp/policy.yaml')
          File.open(tmp.path, 'w') do |f|
            f.puts(<<~YAML)
              ---
              schemaVersion: '1.0'
              description: SSM session user GSA_USERNAME
              sessionType: InteractiveCommands
              parameters:
                gsausername: # not allowed to have underscores :[
                  type: String
                  description: The GSA_USERNAME of the person calling the script.
                  allowedPattern: "^[a-zA-Z0-9-_/]+$"
              properties:
                linux:
                  commands: "GSA_USERNAME={{ gsausername }} /bin/bash"
                  runAsElevated: false
            YAML
          end

          cmd = [
            'aws',
            'ssm',
            'create-document',
            '--name', document_name,
            '--document-format', 'YAML',
            '--document-type', 'Session',
            '--content', "file://#{tmp.path}",
            '--target-type', '/AWS::EC2::Instance',
          ]
          log.debug('system: ' + cmd.join(' '))
          system(*cmd)
        end
      end
    end
  end
end
