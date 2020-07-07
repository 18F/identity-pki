# frozen_string_literal: true

require 'subprocess'

module Cloudlib
  # Cloudlib SSH functionality
  module SSH

    KnownHostsPath = File.expand_path('~/.ssh/known_hosts_cloudlib').freeze
    StrictHostKeyChecking = 'yes' # trust on first use

    class SSHError < Cloudlib::Error; end

    def self.ec2lib_for_vpc(vpc_id)
      # mapping from vpc_id => Cloudlib::EC2 object
      @ec2libs ||= {}

      @ec2libs[vpc_id] ||= Cloudlib::EC2.new_from_vpc_id(vpc_id)
    end

    # This class is a helper to manage SSHing to a single server. It accepts an
    # instance ID or Aws::EC2::Instance object, and provides helper methods to
    # faciliate SSHing to that instance.
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
          raise SSHError.new(msg)
        end

        @cl = SSH.ec2lib_for_vpc(@instance.vpc_id)
      end

      def log
        @log ||= Cloudlib.class_log(self.class, STDERR)
      end

      # Find the host key entry in {KnownHostsPath}, assuming that the known
      # hosts file was created with -o HashKnownHosts=no.
      #
      # @return [String, nil] A known hosts line, or nil.
      #
      def get_known_hosts_entry(hostkeyalias)
        File.read(KnownHostsPath).split("\n").find { |line|
          line.start_with?(hostkeyalias + ' ')
        }
      rescue Errno::ENOENT
        return nil
      end

      def instance_label
        cl.instance_label(instance)
      end

      # @param [Array<String>] ssh_opts SSH options passed at the command line
      #   with "-o". The "-o" is included in the list for each option.
      # @param [Array<String>] local_forwards SSH options related to forwarding
      #   local ports. The "-L" is included in the list for each forward.
      def ssh_cmdline(username: nil, command: nil, port: 22, pkcs11_lib: nil,
                      strict_host_key_checking: nil,
                      verbose: false, quiet: false,
                      ssh_opts: [], local_forwards: [])

        username ||= ENV['GSA_USERNAME']
        unless username
          raise ArgumentError.new('Must pass username or set $GSA_USERNAME')
        end

        name_tag = cl.name_tag(instance)

        cmd = ['ssh', '-l', username]
        cmd += ['-v'] if verbose
        cmd += ['-q'] if quiet
        cmd += ['-p', port.to_s]

        if pkcs11_lib
          cmd += ['-I', pkcs11_lib]
        elsif pkcs11_lib.nil? && ENV.key?('PKCS11_LIB')
          cmd += ['-I', ENV['PKCS11_LIB']]
        end

        hostkey_alias = "#{instance.instance_id}:#{port}"

        if strict_host_key_checking.nil?
          # Use strict host key checking if the alias is already found in the
          # file, otherwise automatically accept the host key. It's a shame
          # that SSH doesn't have any built-in way to specify this behavior,
          # but our only options are "yes", "no", and "ask".

          if get_known_hosts_entry(hostkey_alias)
            strict_host_key_checking = true
          else
            strict_host_key_checking = false
          end
        end

        cmd += [
          '-o', "HostKeyAlias=#{hostkey_alias}",
          '-o', "UserKnownHostsFile=#{KnownHostsPath}",
          '-o', "StrictHostKeyChecking=#{strict_host_key_checking}",
          '-o', 'HashKnownHosts=no',
        ]

        # Proxy over SSM session
        cmd += [
          '-o',
          "ProxyCommand=sh -c 'aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p'"
        ]

        cmd << instance.instance_id
        cmd += local_forwards
        cmd += ssh_opts

        if command
          if command.is_a?(Array)
            # SSH doesn't respect quoting from arrays anyway
            # TODO do some stuff to handle quoted arrays by shell quoting them
            # automagically
            log.debug('SSH array quoting not implemented, mashing array to str')
            cmd << command.join(' ')
          else
            cmd << command
          end
        end

        cmd
      end

      # Replace this process with SSH by generating an SSH command line and
      # calling exec to run it.
      #
      # @return DOES NOT RETURN
      #
      # @param [Hash] ssh_cmdline_opts Options passed to {#ssh_cmdline}
      #
      # @see #ssh_cmdline
      #
      def ssh_exec(ssh_cmdline_opts: {})
        cmd = ssh_cmdline(**ssh_cmdline_opts)
        log.debug('exec: ' + cmd.inspect)
        exec(*cmd)
      end

      # Generate an SSH command line and run it in a subprocess.
      # @param [Hash] ssh_cmdline_opts Options passed to {#ssh_cmdline}
      # @see #ssh_cmdline
      # @return [Process::Status]
      def ssh_subprocess(check_call: true, ssh_cmdline_opts: {})
        cmd = ssh_cmdline(**ssh_cmdline_opts)
        log.debug('+ ' + cmd.join(' '))
        if check_call
          Subprocess.check_call(cmd)
        else
          Subprocess.call(cmd)
        end
      end

      # Generate an SSH command line and run it in a subprocess, saving output
      # @param [Hash] ssh_cmdline_opts Options passed to {#ssh_cmdline}
      # @see #ssh_cmdline
      # @return String
      def ssh_subprocess_output(ssh_cmdline_opts: {})
        cmd = ssh_cmdline(**ssh_cmdline_opts)
        log.debug('+ ' + cmd.join(' '))
        Subprocess.check_output(cmd)
      end
    end

    # Helper class for running multi-threaded SSH to many servers at once.
    class Multi
      attr_reader :instances

      # @param instances [Array<Aws::EC2::Instance>]
      #
      def initialize(instances:)
        @instances = instances
      end

      def log
        @log ||= Cloudlib.class_log(self.class, STDERR)
      end

      # @param command [String] SSH command to execute
      # @param ssh_cmdline_opts [Hash] Options to pass to
      #   {Single#ssh_subprocess}
      # @param return_output [Boolean, nil] Whether to collect standard output
      #
      def ssh_threads(command:, ssh_cmdline_opts: {}, return_output: nil)
        ssh_cmdline_opts[:command] = command

        log.info('SSH::Multi.ssh_threads with: ' +
                 instances.map(&:instance_id).inspect)
        singles = instances.map { |i| SSH::Single.new(instance: i) }
        threads = singles.map { |s|
          Thread.new {
            Thread.current[:single] = s
            if return_output
              s.ssh_subprocess_output(ssh_cmdline_opts: ssh_cmdline_opts)
            else
              s.ssh_subprocess(check_call: false,
                               ssh_cmdline_opts: ssh_cmdline_opts)
            end
          }
        }

        threads.map(&:join)

        succeeded = print_report(threads, return_output)

        if return_output
          output_hash = Hash[threads.map { |t| [t[:single].instance.instance_id,
                                                t.value] }]
        else
          output_hash = nil
        end
        {success: succeeded, threads: threads, outputs: output_hash}
      end

      def print_report(threads, with_output=false)
        all_succeeded = true

        threads.each do |t|
          # get SSH::Single instance from thread variable
          single = t[:single]

          unless single.is_a?(SSH::Single)
            raise "Somehow #{t.inspect} doesn't have correct :single var"
          end

          # thread return value
          retval = t.value

          if with_output
            return_type_ok = retval.is_a?(String)
          else
            return_type_ok = retval.is_a?(Process::Status)
          end

          unless return_type_ok
            raise "Somehow #{single.inspect} thread returned #{retval.inspect}"
          end

          if with_output
            next # we got a String back, so this thread succeeded
          end

          if retval.exited?
            label = single.instance_label
            if retval.success?
              log.info("#{label} returned exit status #{retval.exitstatus}")
            else
              log.error("#{label} returned exit status #{retval.exitstatus}")
              all_succeeded = false
            end
          else
            log.error("#{single.instance_label} failed with #{retval.inspect}")
            all_succeeded = false
          end
        end

        if all_succeeded
          log.info('All hosts succeeded')
        else
          log.error('Had some failures')
        end

        all_succeeded
      end
    end
  end
end
