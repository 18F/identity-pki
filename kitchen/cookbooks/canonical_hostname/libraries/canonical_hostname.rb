require 'aws-sdk-ec2'

# This class manages building the proper hostname for an instance.
class Chef::Recipe::CanonicalHostname

  # Given an Aws instance object, as returned from the ruby sdk, use the tags on
  # the instance and the instance id to build the canonical hostname.
  #
  # Falls back to the IP and logs a warning if the instance doesn't have the
  # proper tags set.
  #
  # @param instance [Aws::EC2::Instance] the instance to build the hostname for.
  # @return [String] the hostname for the instance.
  def self.build_hostname(instance, print_warnings: true)
    prefix = domain = nil
    instance.tags.each do |tag|
      if tag['key'] == "prefix"
        prefix = tag['value']
      end
      if tag['key'] == "domain"
        domain = tag['value']
      end
    end
    if !prefix || !domain
      msg = "Missing required hostname tags on instance: #{instance.id}"
      Chef::Log.warn(msg) if print_warnings
      # Just return the instance ID if we can't build a hostname, so we get some
      # guarantee of uniqueness.
      return "#{instance.id}"
    end
    return "#{prefix}-#{instance.id}.#{domain}"
  end

  # Gets the hostname of the current instance.
  #
  # @return [String] the hostname of the instance.
  def self.get_hostname
    ec2 = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
    return build_hostname(ec2.instance(Chef::Recipe::AwsMetadata.get_aws_instance_id))
  end
end
