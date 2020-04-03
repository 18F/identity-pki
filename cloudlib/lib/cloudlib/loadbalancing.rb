require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-resourcegroupstaggingapi'

module Cloudlib
  def self.loadbalancing
    ElasticLoadBalancingV2.new_resource
  end

  class ElasticLoadBalancingV2
    attr_reader :loadbalancing
    attr_reader :tagging_api

    def self.new_resource
      Aws::ElasticLoadBalancingV2::Resource.new
    end

    def self.new_tagging_api_client
      Aws::ResourceGroupsTaggingAPI::Client.new
    end

    def initialize(env: nil)
      @loadbalancing = self.class.new_resource
      @tagging_api = self.class.new_tagging_api_client
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

    def find_target_group_arns_by_tags(env:, health_role:)
      log.info('Looking up ARN for target group ' +
               {env: env, health_role: health_role}.inspect)

      # We have to use the tagging API to locate the ARNs since there's no
      # ELBv2 API native way to do it. (ugh)

      tag_filters = [
        {key: 'prefix', values: [env]},
        {key: 'health_role', values: [health_role]},
      ]

      log.debug('Filters: ' + tag_filters.inspect)

      arns = tagging_api.get_resources(
        tag_filters: tag_filters,
        resource_type_filters: ['elasticloadbalancing:targetgroup']
      ).resource_tag_mapping_list.map(&:resource_arn)

      if arns.empty?
        raise NotFound.new('No target groups found for ' +
                           {env: env, health_role: health_role}.inspect)
      end

      arns
    end

    def find_target_health_data(environment, role)
      arns = find_target_group_arns_by_tags(env: environment, health_role: role)

      target_health_descriptions = []

      arns.each do |arn|
        log.info("Looking up health data for target group ARN #{arn}")
        result = loadbalancing.client.describe_target_health(
          { target_group_arn: arn }
        )

        target_health_descriptions.concat(result.target_health_descriptions)
      end

      target_health_descriptions
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

  end
end
