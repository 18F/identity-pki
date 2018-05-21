module Cloudlib
  def self.loadbalancing
    ElasticLoadBalancingV2.new_resource
  end

  class ElasticLoadBalancingV2
    attr_reader :loadbalancing

    def self.new_resource
      Aws::ElasticLoadBalancingV2::Resource.new
    end

    def initialize(env: nil)
      @loadbalancing = self.class.new_resource
    end

    def find_target_group_arn_by_name(target_group_name)
      log.info("Looking up ARN for target group named #{target_group_name}")

      result = loadbalancing.client.describe_target_groups({
        names: [target_group_name],
      })
      found = result.target_groups
      if found.length > 1
        raise ManyFound.new("Found multiple target groups: " + found.inspect)
      end
      if found.empty?
        raise NotFound.new("No groups found for name: #{target_group_name.inspect}")
      end
      found.first.target_group_arn
    end

    def target_group_name(environment, role)
      # Here we just hardcode the naming format we're using.
      case role
        when "idp"
          "#{environment}-ssl-target-group"  
        when "app"
          "#{environment}-app-ssl"
        else
          NotFound.new("No target group for role #{role}: only idp and app " +
                       "are supported at present.")
      end
    end

    def find_target_health_data(environment, role)
      arn = find_target_group_arn_by_name(target_group_name(environment, role))
      log.info("Looking up health data for target group ARN #{arn}")
      result = loadbalancing.client.describe_target_health({
        target_group_arn: arn,
      })
      result.target_health_descriptions
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

  end
end
