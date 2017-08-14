require 'subprocess'

module Cloudlib
  module SSH

    KnownHostsPath = File.expand_path('~/.ssh/known_hosts_cloudlib').freeze
    StrictHostKeyChecking = 'yes' # trust on first use
    JumphostName = 'jumphost'

    def self.ec2lib_for_vpc(vpc_id)
      # mapping from vpc_id => Cloudlib::EC2 object
      @ec2libs ||= {}

      @ec2libs[vpc_id] ||= Cloudlib::EC2.new(vpc_id: vpc_id)
    end

    class Single

      attr_reader :cl
      attr_reader :instance

      # @param [String] instance_id
      # @param [Aws::EC2::Instance] instance
      def initialize(instance_id: nil, instance: nil)
        if (instance_id && instance) || (!instance_id && !instance)
          raise ArgumentError.new("must pass one of instance_id or instance")
        end

        @ec2 = Cloudlib::EC2.new_resource

        if instance_id
          instance = @ec2.instance(instance_id)
        end

        @instance = instance

        @cl = SSH.ec2lib_for_vpc(@instance.vpc_id)
      end

      def log
        return @log if @log
        @log = Logger.new(STDERR)
        @log.progname = self.class.name
        @log
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

      # @param [Boolean, nil] use_jumphost Whether to try to find a jumphost to
      #   SSH through. If set to nil, auto determine based on instance name.
      def ssh_cmdline(username: nil, command: nil, port: 22, pkcs11_lib: nil,
                      strict_host_key_checking: nil, use_jumphost: nil,
                      verbose: false, quiet: false,
                      ssh_opts: [])

        username ||= ENV['GSA_USERNAME']
        unless username
          raise ArgumentError.new('Must pass username or set $GSA_USERNAME')
        end

        name_tag = cl.name_tag(instance)

        if use_jumphost.nil?
          if name_tag.include?(JumphostName)
            use_jumphost = false
          else
            log.debug('Automatically using jumphost')
            use_jumphost = true
          end
        end

        cmd = ['ssh', '-l', username]
        cmd += ['-v'] if verbose
        cmd += ['-q'] if quiet
        cmd += ['-p', port.to_s]

        if pkcs11_lib
          cmd += ['-I', pkcs11_lib]
        end

        hostkey_alias = "[#{instance.instance_id}]:#{port}"

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
          '-o', 'HashKnownHosts=no'
        ]

        if use_jumphost
          log.debug('Finding a jumphost to use')
          jumphost = @cl.find_jumphost

          log.debug("Found #{@cl.instance_label(jumphost)}")

          jumphost_ssh_single = self.class.new(instance: jumphost)

          netcat_host = instance.private_ip_address + ':' + port.to_s

          proxycommand = jumphost_ssh_single.ssh_cmdline(
            username: username, port: port, pkcs11_lib: pkcs11_lib,
            use_jumphost: false, verbose: verbose, quiet: quiet,
            ssh_opts: ['-W', netcat_host] + ssh_opts
          )

          cmd += ['-o', 'ProxyCommand=' + proxycommand.join(' ')]

          cmd << name_tag
        else
          cmd << instance.public_ip_address
        end

        cmd += ssh_opts

        if command
          if command.is_a?(Array)
            # SSH doesn't respect quoting from arrays anyway
            # TODO do some magic to handle quoted arrays in a less surprising
            # way
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
      # @see #ssh_cmdline
      #
      def ssh_exec(*args)
        cmd = ssh_cmdline(*args)
        log.debug('exec: ' + cmd.inspect)
        exec(*cmd)
      end

      # Generate an SSH command line and run it in a subprocess.
      # @return [Process::Status]
      def ssh_subprocess(*args)
        cmd = ssh_cmdline(*args)
        log.debug('+ ' + cmd.join(' '))
        Subprocess.check_call(cmd)
      end
    end

    class Multi
      attr_reader :instances

      def initialize(name_pattern:)
        cl = Cloudlib::EC2.new
        @instances = cl.list_instances_by_name(name_pattern, in_vpc: false,
                                               states: ['running'])
      end

      def log
        return @log if @log
        @log = Logger.new(STDERR)
        @log.progname = self.class.name
        @log
      end

      def ssh_threads
        log.info('SSH::Multi.ssh_threads with: ' +
                 instances.map(&:instance_id).inspect)
        singles = instances.map { |i| SSH::Single.new(instance: i) } # TODO: opts
        singles.map { |s|
          Thread.new { s.ssh_subprocess }
        }.map(&:join)
      end

    end

    # @param [String] instance_id Connect to a server by instance ID
    # @param [String] name_pattern Find servers by a name pattern
    #
    def initialize(instance_id: nil, name_pattern: nil)
      if instance_id && name_pattern
        raise ArgumentError.new('Cannot pass instance_id and name_pattern')
      end

      # Mapping from vpc_id => Cloudlib::EC2 object
      @ec2libs = {}

      if instance_id
        ec2 = Cloudlib::EC2.new_resource
        @instance = ec2.instance(instance_id)
        @multi = false
      end

      if name_pattern
        cl = Cloudlib::EC2.new
        @instances = cl.list_instances_by_name(name_pattern, in_vpc: false,
                                               states: ['running'])

        if @instances.length == 1
          @instance = @instances.first
          @multi = false
        else
          @multi = true
        end
      end
    end

  end
end
