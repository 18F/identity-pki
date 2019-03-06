variable "app_sg_ssh_cidr_blocks" { type="list" }
variable "ci_sg_ssh_cidr_blocks"  {
    type="list"
    default = ["127.0.0.1/32"] # hack to allow an empty list, which terraform can't handle
    description = "List of CIDR blocks to allow into all NACLs/SGs.  Only use in the CI VPC."
}
variable "power_users" { type="list" }
# unallocated: "172.16.33.96/28"   # 172.16.33.96  - 172.16.33.111
# unallocated: "172.16.33.112/28"  # 172.16.33.112 - 172.16.33.115
variable "db1_subnet_cidr_block"  { default = "172.16.33.32/28" } # 172.16.33.32 - 172.16.33.47
variable "db2_subnet_cidr_block"  { default = "172.16.33.48/28"} # 172.16.33.48 - 172.16.33.63
variable "db3_subnet_cidr_block"  { default = "172.16.33.64/28"} # 172.16.33.64 - 172.16.33.79
variable "idp1_subnet_cidr_block"  { default = "172.16.33.128/27" } # 172.16.33.128 - 172.16.33.159
variable "idp2_subnet_cidr_block"  { default = "172.16.33.160/27" } # 172.16.33.160 - 172.16.33.191
variable "idp3_subnet_cidr_block"  { default = "172.16.33.192/27" } # 172.16.33.192 - 172.16.33.223
variable "alb1_subnet_cidr_block"  { default = "172.16.33.224/28" } # 172.16.33.224 - 172.16.33.239
variable "alb2_subnet_cidr_block"  { default = "172.16.33.240/28" } # 172.16.33.240 - 172.16.33.255
variable "jumphost1_subnet_cidr_block"  { default = "172.16.32.32/28" } # 172.16.32.32  - 172.16.34.47
variable "jumphost2_subnet_cidr_block"  { default = "172.16.32.48/28" } # 172.16.32.48  - 172.16.34.63
variable "public1_subnet_cidr_block" { default = "172.16.32.64/26" } # 172.16.34.64 - 172.16.34.127
variable "public2_subnet_cidr_block" { default = "172.16.32.128/26" } # 172.16.34.128 - 172.16.34.191
variable "public3_subnet_cidr_block" { default = "172.16.32.192/26" } # 172.16.34.192 - 172.16.34.255
variable "private1_subnet_cidr_block" { default = "172.16.35.0/26" } # 172.16.35.0 - 172.16.35.63
variable "private2_subnet_cidr_block" { default = "172.16.35.64/26" } # 172.16.35.64 - 172.16.35.127
variable "private3_subnet_cidr_block" { default = "172.16.35.128/26" } # 172.16.35.128 - 172.16.35.191
variable "vpc_cidr_block"               { default = "172.16.32.0/22" }  # 172.16.32.0   - 172.16.35.255

# proxy settings
variable "proxy_server" { default = "obproxy.login.gov.internal" }
variable "proxy_port" { default = "3128" }
variable "no_proxy_hosts" { default = "localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,metadata.google.internal" }

variable "proxy_enabled_roles" {
  type = "map"
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  default = {
    unknown = 0

    app = 0
    idp = 0
    jumphost = 0
    outboundproxy = 0
    pivcac = 0
  }
}

#FIXME referrer must define+use SG resource reference
variable "redshift_sg_id" {
  type = "map"
  default = {
    dev = "sg-6a8d8710"
    qa = "sg-0a584d70"
    int = "sg-aef2a8d4"
    dm = "sg-4c156f36"
    staging = "sg-cf5416b5"
    prod = "sg-12807b6f"
  }
}

#FIXME referrer must use EIP resource reference
variable "redshift_cidr_block" {
  type = "map"
  default = {
    dev = "34.214.42.173/32"
    qa = "35.160.215.243/32"
    int = "34.211.57.255/32"
    dm = "54.148.147.138/32"
    staging = "54.68.178.165/32"
    prod = "52.13.170.174/32"
  }
}

variable "analytics_vpc_peering_enabled" {
    description = "Whether to enable VPC peering with the analytics VPC. Set this to 1 once it exists."
    default = 0
}
variable "analytics_cidr_block" {
    description = "Analytics VPC CIDR block"
    default = ""
}
variable "analytics_vpc_id" {
    description = "Analytics VPC ID for peer side of connection"
    default = ""
}
variable "analytics_redshift_security_group_id" {
    description = "Security group ID of redshift in the peered analytics VPC"
    default = ""
}

variable "analytics_lambda_arn_for_s3_notify" {
    description = "The ARN of the analytics lambda that should be notified when new files are uploaded to the logstash S3 logs bucket. If empty, no lambda will be notified. This should be the same as aws_lambda_function.analytics_lambda.arn in the terraform-analytics directory."
    default = ""
}

# CIDR block that is carved up for both the ASG elasticsearch instances and the
# elasticsearch ELBs.
# Range: 172.16.32.128 -> 172.16.32.191
variable "elasticsearch_cidr_block" { default = "172.16.34.128/26" }

# CIDR block that is carved up for both the ASG elk instances and the elk ELBs.
# Range: 172.16.34.192 -> 172.16.34.255
variable "elk_cidr_block" { default = "172.16.34.192/26" }

variable "ami_id_map" {
  type = "map"
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default = {
  }
}

variable "route53_id" {}
variable "apps_enabled" { default = 0 }

variable "legacy_log_bucket_name" {
    description = "Whether to use the legacy log bucket scheme (login-gov-$env-logs) vs the new one (login-gov-logs-$env.$acct_id-$region)"
    default = 1
}

variable "elasticache_redis_node_type" {
    description = "Instance type used for redis elasticache. Changes incur downtime."
    # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
    default = "cache.m3.medium"
}

variable "elasticsearch_volume_size" {
    description = "EBS volume size for elasticsearch hosts"
    # allowed values: 300 - 1000
    default = 300
}

variable "use_multi_az_redis" {
    description = "Whether to use the new multi-AZ elasticache redis cluster. (Repoints DNS CNAME)"
    default = 0
}

# prod/test environment flags
variable "basic_auth_enabled" {
    description = "Whether HTTP basic auth is enabled (controls ELB expected HTTP status code"
}
variable "asg_prevent_auto_terminate" {
    description = "Whether to protect auto scaled instances from automatic termination"
}
variable "enable_deletion_protection" {
    description = "Whether to protect against API deletion of certain resources"
}

variable "asg_enabled_metrics" {
    type = "list"
    description = "A list of cloudwatch metrics to collect on ASGs https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#enabled_metrics"
    default = []
}

# https://downloads.chef.io/chef/stable/13.8.5#ubuntu
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

variable "client" {}
variable "env_name" { }
variable "instance_type_app" { default = "c5.large" }
variable "instance_type_elk" { default = "c5.large" }
variable "instance_type_es" { default = "c5.large" }
variable "instance_type_idp" { default = "c5.large" }
variable "instance_type_jumphost" { default = "c5.large" }
variable "instance_type_pivcac" { default = "c5.large" }
variable "instance_type_outboundproxy" { default = "c5.large" }
variable "name" { default = "login" }
variable "region" { default = "us-west-2" }
variable "availability_zones" { default = ["us-west-2a","us-west-2b","us-west-2c"] }
variable "version_info_bucket" {}
variable "version_info_region" {}

variable "root_domain" {
    description = "DNS domain to use as the root domain, e.g. login.gov"
}

# Auto scaling flags
variable "asg_auto_recycle_enabled" {
    default = 0
    description = "Whether to automatically recycle IdP/app/outboundproxy servers every 6 hours"
}
variable "asg_auto_recycle_use_business_schedule" {
    default = 0
    description = "If set to 1, recycle only once/day during business hours Mon-Fri, not every 6 houts"
}

# Auto scaling group desired counts
variable "asg_jumphost_desired" { default = 0 }
variable "asg_idp_min" { default = 0 }
variable "asg_idp_desired" { default = 0 }
variable "asg_idp_max" { default = 8 }
variable "asg_elasticsearch_desired" { default = 0 }
variable "asg_elk_desired" { default = 0 }
variable "asg_app_min" { default = 0 }
variable "asg_app_desired" { default = 0 }
variable "asg_app_max" { default = 8 }
variable "pivcac_nodes" { default = 2 }
variable "asg_outboundproxy_desired" { default = 3 }
variable "asg_outboundproxy_min" { default = 1 }
variable "asg_outboundproxy_max" { default = 9 }

variable "idp_web_acl_id" {
    default = "eb5d2b12-a361-4fa0-88f2-8f632f6a9819"
    description = "WAF Web ACL ID to attach to this environment's ALBs (shouldn't need to be changed). Only used when enable_waf=true."
    # Get this from https://console.aws.amazon.com/waf/home?region=us-west-2#/webacls
    # or `aws waf-regional list-web-acls`
}
variable "enable_waf" {
    default = false # TODO FIXME this is treated as "false" since terraform doesn't have booleans
    description = "Enable WAF to filter ingress traffic."
    # See ../../doc/technical/waf.md
}

# Several variables used by the terraform-modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref_default" {
    default = ""
    description = <<EOM
Git ref in identity-devops for provision.sh to check out. If set, this
overrides the default "stages/<env>" value in locals. This var will be
overridden by any role-specific value set in bootstrap_main_git_ref_map.
EOM
}
variable "bootstrap_main_git_ref_map" {
  type = "map"
  description = "Mapping from server role to the git ref in identity-devops for provision.sh to check out."
  default = {
  }
}
variable "bootstrap_main_s3_ssh_key_url" {
    default = ""
    description = "S3 path to find an SSH key for cloning identity-devops, overrides the default value in locals if set."
}
variable "bootstrap_main_git_clone_url" {
    default = "git@github.com:18F/identity-devops"
    description = "URL for provision.sh to use to clone identity-devops"
}
variable "bootstrap_private_git_ref" {
    default = "master"
    description = "Git ref in identity-devops-private for provision.sh to check out."
}
variable "bootstrap_private_s3_ssh_key_url" {
    default = ""
    description = "S3 path to find an SSH key for cloning identity-devops-private, overrides the default value in locals if set."
}
variable "bootstrap_private_git_clone_url" {
    default = "git@github.com:18F/identity-devops-private"
    description = "URL for provision.sh to use to clone identity-devops-private"
}

# The following two AMIs should be built at the same time and identical, even
# though they will have different IDs. They should be updated here at the same
# time, and then released to environments in sequence.
variable "default_ami_id_sandbox" {
    default = "ami-0abee874cb5f2a1cf" # 2019-01-29
    description = "default AMI ID for environments in the sandbox account"
}

variable "default_ami_id_prod" {
    default = "ami-0f9e95fe944c4fa62" # 2019-01-29
    description = "default AMI ID for environments in the prod account"
}

variable "high_priority_sns_hook" {
    description = "ARN of SNS topic for high-priority pages"
}

variable "page_devops" {
    default = 0
    description = "Whether to page for high-priority Cloudwatch alarms"
}

locals {
  bootstrap_main_s3_ssh_key_url = "${var.bootstrap_main_s3_ssh_key_url != "" ? var.bootstrap_main_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.identity-devops.deploy"}"
  bootstrap_private_s3_ssh_key_url = "${var.bootstrap_private_s3_ssh_key_url != "" ? var.bootstrap_private_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.id-do-private.deploy"}"
  bootstrap_main_git_ref_default = "${var.bootstrap_main_git_ref_default != "" ? var.bootstrap_main_git_ref_default : "stages/${var.env_name}"}"
  account_default_ami_id = "${data.aws_caller_identity.current.account_id == "555546682965" ? var.default_ami_id_prod : var.default_ami_id_sandbox}"

  // https://github.com/hashicorp/terraform/issues/12453
  // If page_devops is true, we want a list containing both the paging and Slack
  // topics. Otherwise we want the Slack topic in a list by itself. The only
  // way to generate a list conditionally is to use this split/join hack.
  high_priority_alarm_actions = [
    "${split(",", var.page_devops
                  ? join(",", list(var.high_priority_sns_hook,
                                   var.slack_events_sns_hook_arn))
                  : join(",", list(var.slack_events_sns_hook_arn)))}"]
}

# These variables are used to toggle whether certain services are enabled.
#
# NOTE: These must be numbers, as terraform does not support boolean values,
# only numbers and strings.
#
# See: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

variable "alb_enabled" {
    default = 1
    description = "Enable ALB for idp hosts"
}

variable "cloudfront_tlstest_enabled" {
    default = 0
    description = "Enable the cloudfront endpoints for testing SNI and TLSv1.2 compatibility"
}

variable "alb_http_port_80_enabled" {
    default = 1
    description = "Whether to have ALB listen on HTTP port 80 (not just HTTPS 443)"
}

variable "acm_certs_enabled" {
    default = 1
    description = "Whether to look for AWS ACM certificates. Set this to 0 to ignore ACM certs, which is useful for terraform destroy."
}

variable "pivcac_service_enabled" {
    default = 0
    description = "Whether to run the microservice for PIV/CAC authentication"
}

variable "kmslogging_enabled" {
    default = 0
    description = "Whether to enable KMS logging data"
}

# This variable is needed for service discovery

variable "certificates_bucket_name_prefix" {
    description = "Base name for the self signed certificates bucket used for service discovery"
    default = "login-gov-internal-certs-test"
}

# This is needed so the application can download its secrets

variable "app_secrets_bucket_name_prefix" {
    description = "Base name for the bucket that contains application secrets"
    default = "login-gov-app-secrets"
}

# This variable is used to allow access to 80/443 on the general internet
# Set it to [] to turn access off, "0.0.0.0/0" to allow it.
variable "outbound_subnets" {
  default = ["0.0.0.0/0"]
  type="list"
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
}

# This is useful for granting a foreign environment's idp role access to this environment's KMS key
variable "db_restore_role_arns" {
    default = []
    description = "Name of role used to restore db data to another env (e.g. arn:aws:iam::555546682965:role/dm_idp_iam_role)"
}

variable "slack_events_sns_hook_arn" {
    description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
}

