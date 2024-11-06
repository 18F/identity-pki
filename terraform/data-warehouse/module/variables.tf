locals {
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? (
    var.bootstrap_private_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.id-do-private.deploy"

  bootstrap_private_git_ref = var.bootstrap_private_git_ref != "" ? (
  var.bootstrap_private_git_ref) : "main"

  bootstrap_main_s3_ssh_key_url = var.bootstrap_main_s3_ssh_key_url != "" ? (
    var.bootstrap_main_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.identity-devops.deploy"

  bootstrap_main_git_ref_default = var.bootstrap_main_git_ref_default != "" ? (
  var.bootstrap_main_git_ref_default) : "main"

  account_default_ami_id = var.base_ami_analytics_sandbox_uw2

  github_ipv4_cidr_blocks = sort(data.github_ip_ranges.meta.git_ipv4)
  network_zones           = toset(keys(local.network_layout[var.region][var.env_type]._zones))
  default_endpoint_security_group_ids = [
    aws_security_group.kms_endpoint.id,
    aws_security_group.ssm_endpoint.id,
    aws_security_group.ssmmessages_endpoint.id,
    aws_security_group.ec2_endpoint.id,
    aws_security_group.ec2messages_endpoint.id,
    aws_security_group.logs_endpoint.id,
    aws_security_group.monitoring_endpoint.id,
    aws_security_group.secretsmanager_endpoint.id,
    aws_security_group.sts_endpoint.id,
    aws_security_group.events_endpoint.id,
    aws_security_group.sns_endpoint.id
  ]
  analytics_lb_interface_cidr_blocks = []
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
      "logs",
      "monitoring",
      "rds",
      "redshift-data",

      "s3",
      "secretsmanager",
      "sns",
      "sqs",
      "ssm",
      "ssmmessages",
      "sts",
  ])))
  low_priority_alarm_actions      = flatten([var.slack_events_sns_hook_arn, var.additional_low_priority_sns_topics])
  moderate_priority_alarm_actions = flatten([var.slack_alarms_sns_hook_arn, var.additional_moderate_priority_sns_topics])
  high_priority_alarm_actions = var.page_devops == 1 ? flatten([
    var.high_priority_sns_hook,
    local.moderate_priority_alarm_actions
  ]) : local.moderate_priority_alarm_actions
  data_warehouse_lambda_alerts_runbooks = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#lambda-alerts"
}

variable "allowed_analytics_cidr_blocks_v4" { # 159.142.0.0 - 159.142.255.255
  # https://s3.amazonaws.com/nr-synthetics-assets/nat-ip-dnsname/production/ip.json
  type = list(string)
  default = [
    # GSA VPN IPs
    "159.142.0.0/16",
    # New Relic Synthetic IPs in Columbus, OH (US-East-2)
    # https://s3.amazonaws.com/nr-synthetics-assets/nat-ip-dnsname/production/ip-ranges.json
    "3.145.224.0/24",
    "3.145.225.0/25",
    "3.145.234.0/24",
    "18.217.88.49/32",
    "18.221.231.23/32",
    "18.217.159.174/32",
    "3.130.159.252/32",
    "3.13.7.11/32",
    "3.130.155.242/32"
  ]
}

variable "asg_outboundproxy_min" {
  type    = number
  default = 1
}

variable "asg_outboundproxy_max" {
  type    = number
  default = 3
}

variable "asg_outboundproxy_desired" {
  type    = number
  default = 1
}

variable "asg_migration_min" {
  type    = number
  default = 0
}

variable "asg_migration_max" {
  type    = number
  default = 1
}

variable "asg_migration_desired" {
  type    = number
  default = 0
}

variable "asg_prevent_auto_terminate" {
  type        = number
  description = "Whether to protect auto scaled instances from automatic termination"
  default     = 0
}

# Several variables used by the modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref_default" {
  type        = string
  default     = "main"
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
  type        = string
  default     = ""
  description = "S3 path to find an SSH key for cloning identity-devops, overrides the default value in locals if set."
}

variable "bootstrap_main_git_clone_url" {
  type        = string
  default     = "git@github.com:18F/identity-devops"
  description = "URL for provision.sh to use to clone identity-devops"
}

variable "bootstrap_private_git_ref" {
  type        = string
  default     = "main"
  description = "Git ref in identity-devops-private for provision.sh to check out."
}

variable "bootstrap_private_s3_ssh_key_url" {
  type        = string
  default     = ""
  description = "S3 path to find an SSH key for cloning identity-devops-private, overrides the default value in locals if set."
}

variable "bootstrap_private_git_clone_url" {
  type        = string
  default     = "git@github.com:18F/identity-devops-private"
  description = "URL for provision.sh to use to clone identity-devops-private"
}

variable "chef_download_url" {
  type        = string
  description = "URL for provision.sh to download chef debian package"

  #default = "https://packages.chef.io/files/stable/chef/13.8.5/ubuntu/16.04/chef_13.8.5-1_amd64.deb"
  # Assume chef will be installed already in the AMI
  default = ""
}

variable "ami_id_map" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default     = {}
}

variable "chef_download_sha256" {
  type        = string
  description = "Checksum for provision.sh of chef.deb download"

  #default = "ce0ff3baf39c8c13ed474104928e7e4568a4997a1d5797cae2b2ba3ee001e3a8"
  # Assume chef will be installed already in the AMI
  default = ""
}

variable "env_name" {
  type = string
}

variable "instance_type_analytics" {
  type    = string
  default = "t3.medium"
}

variable "instance_type_migration" {
  type    = string
  default = "t3.medium"
}

variable "instance_type_outboundproxy" {
  type    = string
  default = "t3.medium"
}

variable "instance_type_env_runner" {
  type    = string
  default = "t3.medium"
}

variable "name" {
  type    = string
  default = "login"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "dr_region" {
  type    = string
  default = "us-east-2"
}

variable "fisma_tag" {
  type    = string
  default = "Q-LG"
}

variable "nessusserver_ip" {
  type        = string
  description = "Nessus server's public IP"
  default     = "44.230.151.136/32"
}

variable "proxy_server" {
  type    = string
  default = "obproxy.login.gov.internal"
}

variable "proxy_port" {
  type    = string
  default = "3128"
}

variable "proxy_enabled_roles" {
  type        = map(string)
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  default = {
    unknown       = 1
    outboundproxy = 0
    analytics     = 1
  }
}

variable "root_domain" {
  type        = string
  description = "DNS domain to use as the root domain, e.g. login.gov"
  default     = "analytics.identitysandbox.gov"
}

// variable "route53_id" {}

variable "slack_events_sns_hook_arn" {
  type        = string
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
}

variable "slack_alarms_sns_hook_arn" {
  type        = string
  description = "ARN of SNS topic that will notify the #login-alarms channel in Slack"
}

variable "additional_low_priority_sns_topics" {
  type        = list(any)
  description = "List of additional SNS topics that will be notified for a low-priority alert"
  default     = []
}

variable "additional_moderate_priority_sns_topics" {
  type        = list(any)
  description = "List of additional SNS topics that will be notified for a moderate-priority alert"
  default     = []
}

variable "high_priority_sns_hook" {
  type        = list(any)
  description = "ARN of SNS topic for high-priority pages"
  default     = []
}


variable "use_spot_instances" {
  description = "Use spot instances for roles suitable for spot use"
  type        = number
  default     = 0
}

variable "env_type" {
  type        = string
  default     = "analytics-sandbox"
  description = "The env_type of the application. App-Produciton, App-sandbox, analytics-Production, etc."

  validation {
    condition = contains(
      ["analytics-sandbox", "analytics-prod"]
    , var.env_type)
    error_message = "Environment Type can't be found. Please check the network_layout module for valid environment types or update the validation ruleset for new environment types."
  }
}

variable "cloudwatch_treat_missing_data" {
  type    = string
  default = "notBreaching"
}

variable "analytics_servicename" {
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

variable "pgroup_params" {
  description = "Parameter names/values/methods for the force_ssl parameter group"
  type        = list(any)
  default = [
    {
      name  = "log_lock_waits"
      value = "1"
    },
    {
      name  = "log_min_duration_statement"
      value = "250"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "max_standby_streaming_delay"
      value = "1800000"
    },
    {
      name   = "rds.force_ssl"
      value  = "1"
      method = "pending-reboot"
    },
    {
      name  = "rds.force_autovacuum_logging_level"
      value = "log"
    },
    {
      name  = "log_autovacuum_min_duration"
      value = 1000
    }
  ]
}

variable "login_account_id" {
  type        = string
  description = "Account number for the AWS account for the main login.gov (prod/staging) environments."
  default     = "894947205914"
}

variable "redshift_username" {
  type        = string
  description = "Main User Account of the Redshift Cluster (for automated tasks only, users should use IAM)"
  default     = "superuser"
}

variable "redshift_node_type" {
  type        = string
  description = "Type of nodes in the Redshift cluster."
  default     = "dc2.large"
}

variable "redshift_cluster_type" {
  type        = string
  description = "Type of Redshift cluster."
  default     = "single-node"
}

variable "redshift_number_of_nodes" {
  type        = number
  description = "Number of nodes in the Redshift cluster."
  default     = 1
}

variable "lambda_insights_account" {
  description = "The lambda insights account provided by AWS for monitoring"
  type        = string
  default     = "580247275435"
}

variable "lambda_insights_version" {
  description = "The lambda insights layer version to use for monitoring"
  type        = number
  default     = 38
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
Name of one of the blocks defined in schedule.tf, which defines
the cron schedules for recycling and/or 'autozero' scheduled actions.
MUST match one of the key names in local.rotation_schedules.
EOM
  type        = string
  default     = "nozero_norecycle"
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

variable "asg_analytics_min" {
  type    = number
  default = 1
}

variable "asg_analytics_desired" {
  type    = number
  default = 1
}

variable "asg_analytics_max" {
  type    = number
  default = 8
}

variable "analytics_cpu_autoscaling_enabled" {
  type    = number
  default = 0
}

variable "analytics_cpu_autoscaling_target" {
  type    = number
  default = 90
}

variable "allow_nessus_external_scanning" {
  description = "Enables Nessus to externally scan data-services subnet resources"
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  type    = string
  default = "172.16.0.0/16"
}

variable "prevent_tf_log_deletion" {
  type        = bool
  default     = false
  description = <<EOM
Whether or not to allow Terraform to ACTUALLY destroy the CloudWatch Log Groups
defined in cloudwatch-*-logs.tf (vs. simply removing them from state).
EOM
}

variable "page_devops" {
  default     = 0
  description = "Whether to page for high-priority Cloudwatch alarms"
}

# Disaster Recovery variables

variable "dr_restore_redshift_dw" {
  type    = bool
  default = false
}

variable "dr_redshift_snapshot_identifier" {
  type        = string
  description = "Identifier of the redshift data warehouse snapshot for snapshot recovery"
  default     = ""
}

variable "base_ami_analytics_sandbox_uw2" {
  default     = "ami-0d70dd6bd52d14339" # 2024-11-05 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'base' hosts (outboundproxy) in the analytics-sandbox account
EOM
}

variable "rails_ami_analytics_sandbox_uw2" {
  default     = "ami-06d706cac45130f05" # 2024-11-05 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'rails' hosts in the analytics-sandbox account
EOM
}

variable "data_warehouse_memory_usage_threshold" {
  type        = number
  description = "The threshold memory utilization (as a percentage) for triggering an alert"
  default     = 90
}

variable "data_warehouse_duration_threshold" {
  type        = number
  description = "The duration threshold (as a percentage) for triggering an alert"
  default     = 80
}

variable "enable_portforwarding_ssm_commands" {
  type        = bool
  description = "Allows local connections to Redshift via SSM in an environment"
  default     = false
}

# Gitlab variables

variable "gitlab_enabled" {
  description = "whether to turn on the privatelink to gitlab so that systems can git clone and so on"
  type        = bool
  default     = false
}

variable "gitlab_servicename" {
  description = "the service_name of the gitlab privatelink"
  type        = string
  default     = "com.amazonaws.vpce.us-west-2.vpce-svc-0270024908d73003b"
}

variable "gitlab_hostname" {
  description = "name to write into the internal dns zone"
  type        = string
  default     = "gitlab.login.gov"
}

variable "gitlab_runner_enabled" {
  description = "whether to turn on a gitlab runner for this environment"
  type        = bool
  default     = false
}

variable "gitlab_configbucket" {
  description = "should be used to override where the gitlab server's config bucket is so that the runner knows where to get the runner token"
  type        = string
  default     = "login-gov-production-gitlabconfig-217680906704-us-west-2"
}

variable "gitlab_ecr_repo_accountid" {
  description = "the AWS account ID where it's gitlab lives, so it knows what ECR to pull from"
  type        = string
  default     = "217680906704" # prod

  validation {
    condition     = length(var.gitlab_ecr_repo_accountid) == 12
    error_message = "The Gitlab ECR repository account id is invalid"
  }
}

variable "gitlab_subnet_cidr_block" { # 172.16.35.192 - 172.16.35.223
  type    = string
  default = "172.16.35.192/27"
}
