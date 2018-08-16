#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../cloudlib/lib/cloudlib'
require 'aws-sdk-cloudhsmv2'

# Class for finding and importing CloudHSM security groups into terraform.
class HSMSecurityGroupImporter

  # This is the address that the security group will be imported under
  TerraformSecurityGroupAddress = 'aws_security_group.cloudhsm'

  attr_reader :env_name

  def initialize(env_name:)
    @env_name = env_name
  end

  def log
    @log ||= Cloudlib.cli_log
  end

  def cloudhsm
    @cloudhsm ||= Aws::CloudHSMV2::Client.new
  end

  def get_hsm(vpc_id:)
    log.info("Listing CloudHSM clusters in #{vpc_id.inspect}")
    res = cloudhsm.describe_clusters(filters: {vpcIds: [vpc_id]})
    case res.clusters.length
    when 0
      log.error("Didn't find any CloudHSM clusters in #{vpc_id.inspect}")
      raise Cloudlib::NotFound.new('No CloudHSM cluster found in VPC')
    when 1
      hsm = res.clusters.first
    else
      log.error("Found more than one CloudHSM cluster in #{vpc_id.inspect}")
      log.error("Clusters: #{res.clusters.map(&:cluster_id).inspect}")
      raise Cloudlib::ManyFound.new('Multiple CloudHSM clusters found in VPC')
    end

    log.info("Found CloudHSM cluster: #{hsm.cluster_id}")
    hsm
  end

  def find_security_group
    log.info("Finding VPC for env #{env_name.inspect}")
    ec2mgr = Cloudlib::EC2.new(env: env_name)
    vpc_id = ec2mgr.vpc.vpc_id
    hsm = get_hsm(vpc_id: vpc_id)
    log.info("Associated security group: #{hsm.security_group.inspect}")

    hsm.security_group
  end

  def run_deploy(args, check_output: false)
    deploy_cmd = File.dirname(__FILE__) + '/../deploy'
    cmdline = [deploy_cmd, env_name] + args

    log.info('+ ' + cmdline.join(' '))
    if check_output
      Subprocess.check_output(cmdline)
    else
      Subprocess.check_call(cmdline)
    end
  end

  def maybe_rm_sg_from_tf_state
    rm_sg_from_tf_state if sg_in_tf_state?
  end

  def sg_in_tf_state?
    log.info("Looking for existing SG at #{TerraformSecurityGroupAddress}")
    cmd = %W[terraform-app state list #{TerraformSecurityGroupAddress}]
    out = run_deploy(cmd, check_output: true)
    if out.include?(TerraformSecurityGroupAddress)
      log.info('Found existing security group')
      true
    else
      false
    end
  end

  def rm_sg_from_tf_state
    log.warn("Removing SG from TF state at #{TerraformSecurityGroupAddress}")
    run_deploy(%W[terraform-app state rm #{TerraformSecurityGroupAddress}])
    log.warn('Please delete the orphaned sec group after running terraform')
  end

  def run_terraform_sg_import(sg_id:)
    log.info('Importing security group into terraform state')
    cmd = %W[terraform-app import #{TerraformSecurityGroupAddress} #{sg_id}]
    run_deploy(cmd)

    log.info('Finished importing security group into terraform state')

  rescue StandardError
    log.error('Something went wrong importing SG into terraform state')
    log.error('If the placeholder security group still exists, rerun this')
    log.error('script passing the --delete option')
    raise
  end

  def get_sg_and_import_to_terraform(rm_existing: false)
    sg_id = find_security_group

    if rm_existing
      maybe_rm_sg_from_tf_state
    end

    run_terraform_sg_import(sg_id: sg_id)
  end

  def self.cli_main
    options = {}
    if ARGV.first == '--delete'
      options[:delete] = true
      ARGV.shift
    end

    if ARGV.length != 1
      usage
      exit 1
    end

    env = ARGV.fetch(0)
    importer = self.new(env_name: env)
    importer.get_sg_and_import_to_terraform(rm_existing: options[:delete])
    importer.log.info('All done')
  end

  def self.usage
    STDERR.puts <<-EOM
usage: #{File.basename($0)} [OPTIONS] ENV_NAME

Find a CloudHSM cluster in ENV_NAME and import it into the terraform state
as #{TerraformSecurityGroupAddress}.

Options:
    --delete    Remove from TF state any existing SG at #{TerraformSecurityGroupAddress}
    EOM
  end
end

if $0 == __FILE__
  HSMSecurityGroupImporter.cli_main
end
