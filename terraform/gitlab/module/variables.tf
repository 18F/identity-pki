locals {
  bootstrap_main_s3_ssh_key_url    = var.bootstrap_main_s3_ssh_key_url != "" ? var.bootstrap_main_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? var.bootstrap_private_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default != "" ? var.bootstrap_main_git_ref_default : "stages/${var.env_name}"
  account_default_ami_id           = var.default_ami_id_tooling
  public_subnet_cidrs              = [aws_subnet.publicsubnet1.cidr_block, aws_subnet.publicsubnet2.cidr_block, aws_subnet.publicsubnet3.cidr_block]
  private_subnet_cidrs             = [aws_subnet.privatesubnet1.cidr_block, aws_subnet.privatesubnet2.cidr_block, aws_subnet.privatesubnet3.cidr_block]
  private_subnet_ids               = [aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id, aws_subnet.publicsubnet3.id]
  github_ipv4_cidr_blocks          = sort(data.github_ip_ranges.meta.git_ipv4)
  no_proxy_hosts = join(",", concat([
    "localhost",
    "127.0.0.1",
    "169.254.169.254",
    "169.254.169.123",
    ".login.gov.internal",
    "metadata.google.internal",
    ], formatlist("%s.${var.region}.amazonaws.com", [
      "ec2",
      "ec2messages",
      "events",
      "kms",
      "lambda",
      "monitoring",
      "secretsmanager",
      "sns",
      "sqs",
      "ssm",
      "ssmmessages",
      "sts",
  ])))
}

variable "aws_vpc" {
  default = ""
}

variable "alb3_subnet_cidr_block" { # 172.16.33.208 - 172.16.33.223
  default = "172.16.33.208/28"
}

variable "alb1_subnet_cidr_block" { # 172.16.33.224 - 172.16.33.239
  default = "172.16.33.224/28"
}

variable "alb2_subnet_cidr_block" { # 172.16.33.240 - 172.16.33.255
  default = "172.16.33.240/28"
}

variable "gitlab1_subnet_cidr_block" { # 172.16.32.32  - 172.16.32.47
  default = "172.16.32.32/28"
}

variable "gitlab2_subnet_cidr_block" { # 172.16.32.48  - 172.16.32.63
  default = "172.16.32.48/28"
}

variable "public1_subnet_cidr_block" { # 172.16.32.64 - 172.16.32.127
  default = "172.16.32.64/26"
}

variable "public2_subnet_cidr_block" { # 172.16.32.128 - 172.16.32.191
  default = "172.16.32.128/26"
}

variable "public3_subnet_cidr_block" { # 172.16.32.192 - 172.16.32.255
  default = "172.16.32.192/26"
}

variable "private1_subnet_cidr_block" { # 172.16.35.0 - 172.16.35.63
  default = "172.16.35.0/26"
}

variable "private2_subnet_cidr_block" { # 172.16.35.64 - 172.16.35.127
  default = "172.16.35.64/26"
}

variable "private3_subnet_cidr_block" { # 172.16.35.128 - 172.16.35.191
  default = "172.16.35.128/26"
}

variable "nat_a_subnet_cidr_block" { # 172.16.35.192 - 172.16.35.207
  default = "172.16.35.192/28"
}

variable "nat_b_subnet_cidr_block" { # 172.16.35.208 - 172.16.35.223
  default = "172.16.35.208/28"
}

variable "nat_c_subnet_cidr_block" { # 172.16.35.224 - 172.16.35.239
  default = "172.16.35.224/28"
}

variable "gitlab_subnet_cidr_block" { # 172.16.33.64 - 172.16.33.95
  default = "172.16.33.64/27"
}

variable "allowed_gitlab_cidr_blocks_v4" { # 159.142.0.0 - 159.142.255.255
  # https://s3.amazonaws.com/nr-synthetics-assets/nat-ip-dnsname/production/ip.json
  default = [
    # GSA VPN IPs
    "159.142.0.0/16",
    # New Relic Synthetic IPs in Columbus, OH (US-East-2)
    "18.217.88.49/32",
    "18.221.231.23/32",
    "18.217.159.174/32",
  ]
}

variable "ami_id_map" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default     = {}
}

# Auto scaling flags
variable "asg_auto_recycle_enabled" {
  default     = 0
  description = "Whether to automatically recycle IdP/app/outboundproxy servers every 6 hours"
}

# Auto scaling group desired counts
variable "asg_gitlab_desired" {
  default = 1
}

variable "asg_gitlab_build_runner_desired" {
  default = 1
}

variable "asg_gitlab_deploy_runner_desired" {
  default = 1
}

variable "asg_gitlab_test_runner_desired" {
  default = 1
}

variable "asg_outboundproxy_desired" {
  default = 1
}

variable "asg_outboundproxy_min" {
  default = 1
}

variable "asg_outboundproxy_max" {
  default = 3
}

variable "asg_prevent_auto_terminate" {
  description = "Whether to protect auto scaled instances from automatic termination"
  default     = 0
}

variable "asg_recycle_business_hours" {
  default     = 0
  description = "If set to 1, recycle only once/day during business hours Mon-Fri, not every 6 houts"
}

# Several variables used by the modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref_default" {
  default     = "gitlab-ec2-starterpack"
  description = <<EOM
Git ref in identity-devops for provision.sh to check out. If set, this
overrides the default "stages/<env>" value in locals. This var will be
overridden by any role-specific value set in bootstrap_main_git_ref_map.
EOM

}
variable "bootstrap_main_git_ref_map" {
  type        = map(string)
  description = "Mapping from server role to the git ref in identity-devops for provision.sh to check out."
  default     = {}
}

variable "bootstrap_main_s3_ssh_key_url" {
  default     = ""
  description = "S3 path to find an SSH key for cloning identity-devops, overrides the default value in locals if set."
}

variable "bootstrap_main_git_clone_url" {
  default     = "git@github.com:18F/identity-devops"
  description = "URL for provision.sh to use to clone identity-devops"
}

variable "bootstrap_private_git_ref" {
  default     = "main"
  description = "Git ref in identity-devops-private for provision.sh to check out."
}

variable "bootstrap_private_s3_ssh_key_url" {
  default     = ""
  description = "S3 path to find an SSH key for cloning identity-devops-private, overrides the default value in locals if set."
}

variable "bootstrap_private_git_clone_url" {
  default     = "git@github.com:18F/identity-devops-private"
  description = "URL for provision.sh to use to clone identity-devops-private"
}

# The following two AMIs should be built at the same time and identical, even
# though they will have different IDs. They should be updated here at the same
# time, and then released to environments in sequence.
variable "default_ami_id_tooling" {
  description = "default AMI ID for environments in the tooling account"
}

variable "chef_download_url" {
  description = "URL for provision.sh to download chef debian package"

  #default = "https://packages.chef.io/files/stable/chef/13.8.5/ubuntu/16.04/chef_13.8.5-1_amd64.deb"
  # Assume chef will be installed already in the AMI
  default = ""
}

variable "chef_download_sha256" {
  description = "Checksum for provision.sh of chef.deb download"

  #default = "ce0ff3baf39c8c13ed474104928e7e4568a4997a1d5797cae2b2ba3ee001e3a8"
  # Assume chef will be installed already in the AMI
  default = ""
}

variable "ci_sg_ssh_cidr_blocks" {
  type        = list(string)
  default     = ["127.0.0.1/32"] # hack to allow an empty list, which terraform can't handle
  description = "List of CIDR blocks to allow into all NACLs/SGs.  Only use in the CI VPC."
}

variable "env_name" {
}

variable "instance_type_gitlab" {
  default = "c5.xlarge"
}

variable "instance_type_gitlab_runner" {
  default = "c5.xlarge"
}

variable "instance_type_outboundproxy" {
  default = "t3.medium"
}

variable "name" {
  default = "login"
}

variable "region" {
  default = "us-west-2"
}

variable "dr_region" {
  default = "us-east-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
  default     = "44.230.151.136/32"
}

variable "proxy_server" {
  default = "obproxy.login.gov.internal"
}

variable "proxy_port" {
  default = "3128"
}

variable "proxy_enabled_roles" {
  type        = map(string)
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  default = {
    unknown       = 1
    outboundproxy = 0
    gitlab        = 1
  }
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
  default     = "gitlab.identitysandbox.gov"
}

variable "route53_id" {}

variable "slack_events_sns_hook_arn" {
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
}

variable "use_spot_instances" {
  description = "Use spot instances for roles suitable for spot use"
  type        = number
  default     = 0
}

variable "vpc_cidr_block" { # 172.16.32.0   - 172.16.35.255
  default = "172.16.32.0/22"
}

#######################################################################
# RDS Variables
variable "rds_storage_gitlab" {
  default = "200"
}

# Changing engine or engine_version requires also changing any relevant uses of
# aws_db_parameter_group, which has a family attribute that tightly couples its
# parameter to the engine and version.

variable "rds_engine" {
  default = "postgres"
}

variable "rds_engine_version" {
  default = "13.4"
}

variable "rds_instance_class" {
  default = "db.t3.medium"
}

variable "rds_backup_retention_period" {
  default = "34"
}

variable "rds_backup_window" {
  default = "08:00-08:34"
}

variable "rds_maintenance_window" {
  default = "Sun:08:34-Sun:09:08"
}

variable "rds_password" {
  default = ""
}

variable "rds_username" {
  default = "gitlab"
}

variable "rds_storage_type_gitlab" {
  # possible storage types:
  # standard (magnetic)
  # gp2 (general SSD)
  # io1 (provisioned IOPS SSD)
  description = "The type of EBS storage (magnetic, SSD, PIOPS) used by the gitlab database"
  default     = "gp2"
}

variable "rds_iops_gitlab" {
  description = "If PIOPS storage is used, the number of IOPS provisioned"
  default     = 0
}

variable "db1_subnet_cidr_block" { # 172.16.33.32 - 172.16.33.47
  default = "172.16.33.32/28"
}

variable "db2_subnet_cidr_block" { # 172.16.33.48 - 172.16.33.63
  default = "172.16.33.48/28"
}

# gitaly EBS volume config here
variable "gitlab_az" {
  description = "AZ that gitlab needs to live in so that it can find the EBS volume"
  # NOTE:  If you change this, you need to change the vpc_zone_identifier in aws_autoscaling_group.gitlab
  #        so that it is aws_subnet.gitlab2.id or whatever subnet is in the AZ.  I can't think of an easy
  #        way to turn this into a variable.
  default = "us-west-2a"
}

# elasticache redis config here
variable "elasticache_redis_node_type" {
  description = "Instance type used for redis elasticache. Changes incur downtime."

  # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
  default = "cache.t3.micro"
}

variable "elasticache_redis_engine_version" {
  description = "Engine version used for redis elasticache. Changes may incur downtime."
  default     = "6.x"
}

variable "elasticache_redis_parameter_group_name" {
  default = "default.redis6.x"
}

variable "destination_artifact_accounts" {
  description = "List of AWS accounts we can potentially push artifacts to"
  type        = list(string)
  default     = []
}

variable "destination_idp_static_accounts" {
  description = "List of AWS accounts we can potentially push IDP CDN static assets to"
  type        = list(string)
  default     = []
}

variable "production" {
  description = "If this is set to true, it will try to set up dns/SSL so that you can go to gitlab.login.gov"
  default     = false
}

variable "accountids" {
  type        = list(string)
  description = "list of AWS account ids that we should allow to find the gitlab privatelink service and be allowed to get the gitlab runner token"
  default     = []
  # export TF_VAR_accountids='["1234", "2345", "5678"]'
}

variable "gitlab_backup_retention_days" {
  default = 90
}

variable "use_waf_rules" {
  default     = false
  description = "Whether to use WAF instead of Security Group rules for the ALB. Allows public acccess to some paths."
}

variable "gitlab_runner_enabled" {
  default     = false
  description = "run an env_runner in here"
}

variable "env_runner_gitlab_hostname" {
  description = "Gitlab instance that the env_runner should connect to"
  default     = ""
}

locals {
  env_runner_gitlab_hostname = var.env_runner_gitlab_hostname == "" ? "gitlab.${var.env_name}.${var.root_domain}" : var.env_runner_gitlab_hostname
  env_runner_config_bucket   = var.env_runner_config_bucket == "" ? "login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}" : var.env_runner_config_bucket
  runner_config_bucket       = var.runner_config_bucket == "" ? "login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}" : var.runner_config_bucket
}

variable "gitlab_servicename" {
  description = "the privatelink servicename that we connect with"
  default     = ""
}

variable "env_runner_config_bucket" {
  description = "the config bucket that the env_runner should get it's config from"
  default     = ""
}

variable "runner_config_bucket" {
  description = "the config bucket that all the other runners should get their config from"
  default     = ""
}