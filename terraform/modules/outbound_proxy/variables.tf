variable "use_prefix" {
  type        = bool
  description = <<EOM
Whether or not to use a name_prefix (vs. a name) for resource naming.
EOM
  default     = true
}

variable "external_role" {
  type        = string
  description = <<EOM
Name of an externally-created IAM role for outboundproxy hosts.
Will skip creation of aws_iam_role.obproxy resource if set.
EOM
  default     = ""
}

variable "external_instance_profile" {
  type        = string
  description = <<EOM
Name of an externally-created IAM instance profile for outboundproxy hosts.
Will skip creation of aws_iam_instance_profile.obproxy resource if set.
EOM
  default     = ""
}

variable "create_cpu_policy" {
  type        = bool
  description = "Whether or not to create the obproxy-cpu Auto Scaling Policy."
  default     = true
}

variable "ami_id_map" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default     = {}
}

variable "cloudwatch_retention_days" {
  type        = number
  default     = 0
  description = "Defines the number of days log groups will be retained."
}

# Auto scaling group desired counts
variable "asg_outboundproxy_desired" {
  default = 1
}

variable "asg_outboundproxy_min" {
  default = 1
}

variable "asg_outboundproxy_max" {
  default = 4
}

variable "asg_prevent_auto_terminate" {
  description = "Whether to protect auto scaled instances from automatic termination"
  default     = 0
}

variable "asg_enabled_metrics" {
  type        = list(string)
  description = "A list of cloudwatch metrics to collect on ASGs https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#enabled_metrics"
  default = [
    "GroupStandbyInstances",
    "GroupTotalInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
  ]
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

variable "env_name" {
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "default_ami_id" {
  description = "default AMI ID for environments in the account"
}

variable "slack_events_sns_hook_arn" {
  description = <<EOM
ARN of SNS topic that will notify the appropriate channel
(#login-events / #login-otherevents) in Slack.
EOM
}

variable "name" {
  default = "login"
}

variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "instance_type_outboundproxy" {
  default = "t3.medium"
}

variable "proxy_enabled_roles" {
  type        = map(string)
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  default = {
    unknown                 = 1
    analytics-outboundproxy = 0
    outboundproxy           = 0
    gitlab                  = 1
  }
}

variable "route53_internal_zone_id" {}

variable "use_spot_instances" {
  description = "Use spot instances for roles suitable for spot use"
  type        = number
  default     = 0
}

variable "vpc_id" {
  description = "VPC Used To Launch the Outbound Proxy"
}

variable "proxy_subnet_ids" {
  type        = list(string)
  description = "List of public subnets to use for the outbound proxy ASG"
}

variable "proxy_security_group_id" {
  type        = string
  description = "Main security group (created separately!) for outbound proxy"
}

variable "base_security_group_id" {
  type        = string
  description = "security group used on client side for outbound proxy"
}

variable "hostname" {
  type    = string
  default = "obproxy.login.gov.internal"
}

variable "proxy_for" {
  type        = string
  description = "What the proxy is for, e.g. idp, gitlab, gitlab-runner-test-pool."
  default     = "default"
}

variable "ssm_access_policy" {
  type        = string
  description = "JSON-formatted IAM policy providing access to SSM resources."
}

variable "cloudwatch_treat_missing_data" {
  type    = string
  default = "notBreaching"
}

variable "s3_secrets_bucket_name" {
  description = "Name of bucket used to track user_data"
  default     = ""
}

# Automatic recycling and/or zeroing-out of Auto Scaling Groups on scheduled basis
# See identity-terraform//asg_recycle/schedule.tf for detailed timetables
variable "autoscaling_time_zone" {
  description = "IANA time zone to use with cron schedules. Uses UTC by default."
  type        = string
  default     = "Etc/UTC"
}

variable "autoscaling_schedule_name" {
  description = <<EOM
Name of one of the blocks defined in var.outboundproxy_rotation_schedules, which
defines the cron schedules for recycling and/or 'autozero' scheduled actions.
MUST match one of the key names in var.outboundproxy_rotation_schedules.
EOM
  type        = string
  default     = "nozero_norecycle"
}

variable "use_outboundproxy_rotation_schedules" {
  description = <<EOM
Use the outboundproxy set of cron jobs for recycling (up/down)
and/or zeroing out hosts.
EOM
  type        = bool
  default     = false
}

variable "chef_role" {
  description = <<EOM
  Chef role to be used when provisioning instances. Values include 'outboundproxy'
  and 'analytics-outboundproxy'
  EOM
  type        = string
  default     = "outboundproxy"
}

