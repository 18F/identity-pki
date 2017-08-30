require 'aws-sdk'

# This class abstracts the service discovery from chef recipes so that they can
# get information about other nodes in the environment without needing to know
# details of how that information is found.
class Chef::Recipe::ServiceDiscovery

  class ServiceDiscoveryError < Exception
  end

  # Discover all instances of +service+.  The +node+ argument should be the
  # chef current node object for accessing node attributes.
  #
  # Discover all instances of a given service in the same VPC as the given node.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @param tag [String] the tag specifying the service type.
  # @param values [String] the values of the service type tag to query for.
  # @return [List] list of service objects.
  def self.discover(node, tag, values)
    msg = "Searching for services with tag: #{tag} and values: #{values}"
    Chef::Log.info(msg)
    ec2 = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
    instances = ec2.instances(filters:[{ name: "tag:#{tag}",
                                         values: values },
                                       { name: "instance-state-name",
                                         values: ['running'] },
                                       { name: "vpc-id",
                                         values: [Chef::Recipe::AwsMetadata.get_aws_vpc_id] } ]).to_a
    services = instances.map {|instance| make_service_object(node, instance)}
    msg = "Discovered services: #{services.inspect}"
    Chef::Log.info(msg)
    return services
  end

  # Do any registration needed for the given service.  Currently this is just
  # uploading this instance's certificate to s3, as all other discovery is done
  # through tags.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @return [Hash] this instance's service object.
  def self.register(node)
    ec2 = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
    instance = ec2.instance(Chef::Recipe::AwsMetadata.get_aws_instance_id)
    hostname = Chef::Recipe::CanonicalHostname.build_hostname(instance)
    cert_name = "#{hostname}.crt"
    cert_path = get_attribute(node, 'cert_path')
    put_certificate(node, cert_path, cert_name)
    service = make_service_object(node, instance)
    msg = "Registered service has service object: #{service}."
    Chef::Log.info(msg)
    return service
  end

  # Get the certificate at the given path.  Node is just used to access
  # attributes.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @param path [String] s3 path where the certificate is located.
  # @return [String] contents of the certificate.
  def self.get_certificate(node, path)
    Chef::Recipe::AwsS3.download(certificates_bucket(node),
                                 "#{node.chef_environment}/#{path}")
  end

  # Upload the given certificate to the given path.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @param path [String] path to use when uploading the certificate.
  # @return [String] path in s3 where the certificate was uploaded.
  def self.put_certificate(node, cert_path, s3_path)
    cert_bucket = certificates_bucket(node)
    cert_key = "#{node.chef_environment}/#{s3_path}"
    if File.exists?(cert_path)
      Chef::Recipe::AwsS3.upload(cert_bucket, cert_key,
                                 File.open(cert_path))
      return "#{cert_bucket}/#{cert_key}"
    else
      msg = "No certificate found at #{cert_path}!"
      raise ServiceDiscoveryError(msg)
    end
  end

  # Build the certificate bucket path for the given node, properly namespacing
  # using region and account id.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @return [String] certificates bucket for this instance.
  def self.certificates_bucket(node)
    cert_bucket_prefix = get_attribute(node, 'cert_bucket_prefix')
    aws_region = Chef::Recipe::AwsMetadata.get_aws_region
    aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
    return "#{cert_bucket_prefix}.internal-certs.#{aws_account_id}-#{aws_region}"
  end

  # Make the canonical service object that represents this instance for return
  # to users of this library.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @param instance [Aws::EC2::Instance] the instance to make the object for.
  # @return [Hash] the service object.
  def self.make_service_object(node, instance)
    hostname = Chef::Recipe::CanonicalHostname.build_hostname(instance)
    cert_name = "#{hostname}.crt"
    {
        "hostname" => hostname,
        "certificate" => get_certificate(node, cert_name),
        "instance" => instance
    }
  end

  # Safely retrieve an attribute for the service_discovery cookbook.
  #
  # @param node [Chef::node] the Node currently running Chef.
  # @param key [String] Key of the attribute to get.
  # @return [Object] attribute value, or nil.
  def self.get_attribute(node, key, required: true)
    val = node.fetch('service_discovery', {})[key]
    if val.nil? && required
      raise KeyError.new("Missing required attribute: ['service_discovery'][#{key.inspect}]")
    end
    val
  end
end
