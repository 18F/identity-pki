module Cloudlib
  # @see EC2.new_resource
  def self.ec2
    EC2.new_resource
  end

  class EC2
    attr_reader :ec2
    attr_reader :env

    # Create a new AWS EC2 connection object
    #
    # @return [Aws::EC2::Resource]
    def self.new_resource
      if Aws.config.empty? && !ENV['AWS_PROFILE'] && !ENV['AWS_SECRET_ACCESS_KEY']
        log.warn("No AWS credentials appear set, try `aws configure`?")
      end
      Aws::EC2::Resource.new
    end

    VPC_NAME_PREFIX = 'login-vpc-'

    def initialize(env: nil, vpc_id: nil, from_obj_in_vpc: nil)
      @ec2 = self.class.new_resource

      @env = env if env

      if from_obj_in_vpc
        if vpc_id
          raise ArgumentError.new("Cannot pass from_obj_in_vpc and vpc_id")
        end
        vpc_id = from_obj_in_vpc.vpc_id
      end

      if vpc_id
        @vpc = @ec2.vpc(vpc_id)
        @env ||= name_tag(@vpc).gsub(VPC_NAME_PREFIX, '')
      end
    end

    def self.new_from_vpc_id(vpc_id)
      unless vpc_id
        raise ArgumentError.new("Must pass vpc_id")
      end
      self.new(vpc_id: vpc_id)
    end

    def self.new_from_env(env)
      unless env
        raise ArgumentError.new("Must pass env")
      end
      self.new(env: env)
    end

    def vpc
      @vpc ||= lookup_vpc_for_env(@env)
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

    def self.log
      @log ||= Cloudlib.class_log(self, STDERR)
    end

    # @param [String] environment
    # @return [Aws::EC2::Vpc]
    def lookup_vpc_for_env(environment)
      unless environment
        raise ArgumentError.new("Must pass environment, got #{environment.inspect}")
      end
      name_tag = VPC_NAME_PREFIX + environment
      log.info("Looking for #{name_tag} VPC")
      vpc = get_unique_thing(:vpcs, [{name: 'tag:Name', values: [name_tag]}])
      log.info("Found #{vpc.vpc_id}")
      vpc
    end

    # @param [String] instance_id
    # @return [Aws::EC2::Instance]
    def lookup_instance_by_id(instance_id)
      i = Aws::EC2::Instance.new(id: instance_id)
      i.image_id # ensure exists, memoize
      i
    end

    # @param [Array<String>] states The states of the instances to filter
    # @return [Array<Aws::EC2::Instance>]
    def instances_in_vpc(states: ['running', 'stopped'])
      filters = [
        {name: 'vpc-id', values: [vpc.vpc_id]},
        {name: 'instance-state-name', values: states},
      ]

      list_things(:instances, filters)
    end

    def nonasg_instances_in_vpc(states: ['running', 'stopped'])
      instances_in_vpc(states: states).find_all { |i|
        name = name_tag(i, allow_nil: true)
        label = "#{name.inspect} (#{i.instance_id})"
        case name
        when /\Atest-kitchen/
          log.debug("Ignoring test-kitchen instance: #{label}")
          false
        when /\Aasg-/
          log.debug("Ignoring asg- instance: #{label}")
          false
        when nil
          log.warn("No name tag found on #{i.instance_id}")
          false
        else
          true
        end
      }
    end

    # TODO: pick jumphost within an AZ or pick an ELB jumphost
    def find_jumphost
      # find ASG and non-asg jumphosts
      jumphosts = list_instances_by_name('*jumphost*', in_vpc: true)
      jumphosts.first
    end

    # @param [String,Array<String>] name_tag A name tag pattern, or array of
    #   patterns
    # @param [Boolean] in_vpc Whether to restrict search to within this VPC
    # @param [Array<string>] states A filter for the instance states
    # @return [Array<Aws::EC2::Instance>]
    def list_instances_by_name(name_tag, in_vpc: true, states: ['running'])
      # handle single or Array name_tag
      name_tags_arr = Array(name_tag)

      filters = [
        {name: 'tag:Name', values: name_tags_arr},
        {name: 'instance-state-name', values: states},
      ]

      if in_vpc
        filters << {name: 'vpc-id', values: [vpc.vpc_id]}
      end

      list_things(:instances, filters)
    end

    # Look up a unique object in EC2. Raise ManyFound if multiple objects match
    # the filters.
    #
    # @raise NotFound if no objects are found.
    #
    # @param [Symbol] thing The object to find, such as :instances, :vpcs, etc.
    # @param [Array<Hash>] filters
    #
    def get_unique_thing(thing, filters)
      found = ec2.public_send(thing, filters: filters).to_a
      if found.length > 1
        raise ManyFound.new("Found multiple #{thing}: " + found.inspect)
      end
      if found.empty?
        raise NotFound.new("No #{thing} found for filters: #{filters.inspect}")
      end

      found.first
    end

    # Look up an object in EC2. If multiple objects match the filters, return
    # one of them at random.
    #
    # @raise NotFound if no objects are found.
    #
    # @param [Symbol] thing The object to find, such as :instances, :vpcs, etc.
    # @param [Array<Hash>] filters
    #
    def get_random_thing(thing, filters)
      found = ec2.public_send(thing, filters: filters).to_a
      if found.empty?
        raise NotFound.new("No #{thing} found for filters: #{filters.inspect}")
      end

      # return random thing
      found.sample
    end

    # @param [Symbol] thing The object to find, such as :instances, :vpcs, etc.
    # @param [Array<Hash>] filters
    # @param [Boolean] raise_not_found Whether to raise if no instances found
    # @return [Array]
    #
    def list_things(thing, filters, raise_not_found: true)
      log.debug{"Listing #{thing} with #{filters.inspect}"}
      found = ec2.public_send(thing, filters: filters).to_a
      if found.empty? && raise_not_found
        raise NotFound.new("No #{thing} found for filters: #{filters.inspect}")
      end

      found
    end

    # @param [Symbol] thing The object to find, such as :instances, :vpcs, etc.
    # @param [Array<Hash>] filters
    def get_any_thing(thing, filters)
      found = ec2.public_send(thing, filters: filters).first
      if found.nil?
        raise NotFound.new("No #{thing} found for filters: #{filters.inspect}")
      end

      found
    end

    def name_tag(obj, allow_nil: false)
      self.class.name_tag(obj, allow_nil: allow_nil)
    end

    def fetch_tag(obj, key, allow_nil: false)
      self.class.fetch_tag(obj, key, allow_nil: allow_nil)
    end

    def instance_label(instance)
      self.class.instance_label(instance)
    end

    def classic_hostname_for_instance(instance)
      name = name_tag(instance)

      prefix = fetch_tag(instance, 'prefix')
      domain = fetch_tag(instance, 'domain')

      match = name.match(/\Alogin-([a-z0-9-]+)-([a-z]+)\z/)
      unless match
        raise "Failed to parse #{name.inspect} as login-TYPE-ENV"
      end

      base = match.captures.fetch(0)
      env = match.captures.fetch(1)

      unless domain.start_with?(env + '.')
        raise "domain and Name conflict: #{domain.inspect}, #{name.inspect}"
      end
      unless base.start_with?(prefix)
        raise "prefix and Name conflict: #{prefix.inspect}, #{name.inspect}"
      end

      # FIXME hack to handle worker nonsense
      if prefix == 'worker'
        base = base.gsub('worker', 'worker-')
      end

      return base + '.' + domain
    end

    def self.name_tag(obj, allow_nil: false)
      fetch_tag(obj, 'Name', allow_nil: allow_nil)
    end

    def self.fetch_tag(obj, key, allow_nil: false)
      tag = obj.tags.find {|t| t.key == key }
      if tag
        tag.value
      else
        if allow_nil
          nil
        else
          log.warn("No #{key.inspect} tag found among #{obj.tags.inspect}")
          raise KeyError.new("No #{key.inspect} tag found on #{obj.inspect}")
        end
      end
    end

    def self.instance_label(instance)
      name_tag(instance, allow_nil: true).inspect + ' (' + instance.instance_id + ')'
    end

    # Filter servers by a CLI friendly set of filters
    # @param env [String] Filter servers by env, part of the VPC name
    # @param name_globs [Array<String>] Filter servers by >= 1 Name tag glob
    # @param states [Array<String>] Filter by an array of instance state names
    #
    # @return [Array<Aws::EC2::Instance>]
    #
    def self.cli_find_servers(env: nil, name_globs: nil, states: nil)
      if env
        log.info("Listing servers in #{env.inspect} environment")
        cl = self.new(env: env)
        if name_globs
          log.info("Listing within env by name: #{name_globs.inspect}")
          cl.list_instances_by_name(name_globs, in_vpc: true, states: states)
        else
          cl.instances_in_vpc(states: states)
        end
      else
        unless name_globs
          raise ArgumentError.new("Must pass env or name_globs")
        end
        log.info("Listing servers by name: #{name_globs.inspect}")
        cl = self.new
        cl.list_instances_by_name(name_globs, in_vpc: false, states: states)
      end
    end
  end
end
