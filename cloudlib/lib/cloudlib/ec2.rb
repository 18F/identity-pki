module Cloudlib
  # @see EC2.new_resource
  def self.ec2
    EC2.new_resource
  end

  class EC2
    attr_reader :ec2

    # Create a new AWS EC2 connection object
    #
    # @return [Aws::EC2::Resource]
    def self.new_resource
      Aws::EC2::Resource.new(ec2_options)
    end

    def self.ec2_options
      {
        region: ENV.fetch('AWS_REGION', 'us-west-2'),
      }
    end

    VPC_NAME_PREFIX = 'login-vpc-'

    def initialize(env:)
      @ec2 = self.class.new_resource

      @env = env
    end

    def vpc
      @vpc ||= lookup_vpc_for_env(@env)
    end

    def log
      return @log if @log

      @log = Logger.new(STDERR)
      @log.progname = self.class.to_s
      @log
    end

    # @param [String] environment
    # @return [Aws::EC2::Vpc]
    def lookup_vpc_for_env(environment)
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

    # @param [String] name_tag A name tag pattern
    # @return [Array<Aws::EC2::Instance>]
    def list_instances_by_name(name_tag, in_vpc: true, states: ['running'])
      filters = [
        {name: 'tag:Name', values: [name_tag]},
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

    # @param [Symbol] thing The object to find, such as :instances, :vpcs, etc.
    # @param [Array<Hash>] filters
    # @return [Array]
    #
    def list_things(thing, filters)
      log.debug{"Listing #{thing} with #{filters.inspect}"}
      found = ec2.public_send(thing, filters: filters).to_a
      if found.empty?
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

    def name_tag_for_instance(instance, allow_nil: false)
      tag = instance.tags.find {|t| t.key == 'Name'}
      if tag
        tag.value
      else
        if allow_nil
          nil
        else
          raise KeyError.new("No 'Name' tag found on #{instance.inspect}")
        end
      end
    end
  end
end
