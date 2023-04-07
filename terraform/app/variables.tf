variable "ci_sg_ssh_cidr_blocks" {
  type        = list(string)
  default     = ["127.0.0.1/32"] # hack to allow an empty list, which terraform can't handle
  description = "List of CIDR blocks to allow into all NACLs/SGs.  Only use in the CI VPC."
}

variable "enable_idp_static_bucket" {
  description = "Create public S3 bucket for storing IdP static assets"
  type        = bool
  default     = false
}

variable "force_destroy_idp_static_bucket" {
  description = "Allow destruction of IdP static bucket even if not empty"
  type        = bool
  default     = true
}

variable "enable_idp_cdn" {
  description = "Enable CloudFront distribution serving from idp origin servers"
  type        = bool
  default     = false
}

variable "idp_static_bucket_cross_account_access" {
  description = "Source roles from other accounts allowed access to the bucket"
  type        = list(string)
  default     = []
}

variable "gitlab_subnet_cidr_block" { # 172.16.35.192 - 172.16.35.223
  default = "172.16.35.192/27"
}

variable "vpc_cidr_block" { # 172.16.32.0   - 172.16.35.255
  default = "172.16.32.0/22"
}

# proxy settings
variable "proxy_server" {
  default = "obproxy.login.gov.internal"
}

variable "proxy_port" {
  default = "3128"
}

variable "no_proxy_hosts" {
  default = "localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,lambda.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,sns.us-west-2.amazonaws.com,sqs.us-west-2.amazonaws.com,events.us-west-2.amazonaws.com,metadata.google.internal,sts.us-west-2.amazonaws.com"
}

variable "proxy_enabled_roles" {
  type        = map(string)
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  default = {
    unknown       = 1
    outboundproxy = 0
  }
}

variable "identity_sms_aws_account_id" {
  description = "Account ID of the AWS account used for Pinpoint and SMS sending (identity-sms-*)"
}

variable "identity_sms_iam_role_name_idp" {
  description = "IAM role assumed by the IDP for cross-account access into the above identity-sms-* account."
  default     = "idp-pinpoint"
}

variable "ami_id_map" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default     = {}
}

variable "route53_id" {
}

variable "apps_enabled" {
  description = "Whether or not to build the dashboard/app RDS database + app hosts."
  default     = 1
}

# Each of these variables MUST be a node type that has a NetworkPerformance value
# of 'Up to 5 Gigabit' or higher, or the threshold calculations for the
# elasticache_alarm_critical CloudWatch alarms cannot be set properly!
# Reference: https://aws.amazon.com/ec2/instance-types/

variable "elasticache_redis_node_type" {
  type        = string
  description = "Instance type used for redis elasticache. Changes incur downtime."
  default     = "cache.t3.micro"
}

variable "elasticache_redis_attempts_api_node_type" {
  type        = string
  description = "Instance type used for redis attempts api elasticache. Changes incur downtime."
  default     = "cache.t3.micro"
}

variable "elasticache_redis_cache_node_type" {
  type        = string
  description = "Instance type used for redis elasticache. Changes incur downtime."
  # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
  default = "cache.t3.micro"
}

variable "elasticache_redis_ratelimit_node_type" {
  type        = string
  description = "Instance type used for redis elasticache rate limiting. Changes incur downtime."
  # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
  default = "cache.t3.micro"
}

variable "elasticache_redis_num_cache_clusters" {
  type        = number
  description = "Number of Redis cache clusters."
  default     = 2
}
variable "elasticache_redis_cache_num_cache_clusters" {
  type        = number
  description = "Number of Redis cache clusters for IDP Cache."
  default     = 2
}
variable "elasticache_redis_ratelimit_num_cache_clusters" {
  type        = number
  description = "Number of Redis cache clusters for ratelimiting."
  default     = 2
}

variable "elasticache_redis_engine_version" {
  type        = string
  description = "Engine version used for redis elasticache. Changes may incur downtime."
  default     = "7.0"
}

variable "elasticache_redis_encrypt_at_rest" {
  description = "Enable encryption at rest using customer managed KMS key (CMK)"
  type        = bool
  default     = true
}

variable "elasticache_redis_encrypt_in_transit" {
  description = "Enable TLS for Redis"
  type        = bool
  default     = true
}

variable "elasticache_redis_alarm_threshold_memory" {
  type        = number
  description = "Alert Threshhold for Redis memory utilization"
  default     = 75
}

variable "elasticache_redis_alarm_threshold_memory_high" {
  type        = number
  description = "Critical Alert Threshhold for Redis memory utilization"
  default     = 80
}

variable "elasticache_redis_alarm_threshold_cpu" {
  type        = number
  description = "Alert Threshhold for Redis cpu utilization"
  default     = 70
}

variable "elasticache_redis_alarm_threshold_cpu_high" {
  type        = number
  description = "Critical Alert Threshhold for Redis cpu utilization"
  default     = 80
}

variable "elasticache_redis_alarm_threshold_currconnections" {
  type        = number
  description = "Alert Threshhold for Redis currconnections utilization"
  default     = 40000
}

variable "elasticache_redis_alarm_threshold_currconnections_high" {
  type        = number
  description = "Critical Alert Threshold for Redis currconnections utilization"
  default     = 50000
}

variable "elasticache_redis_alarm_threshold_replication_lag" {
  type        = string
  description = "Alert Threshhold for Redis replication_lag utilization"
  default     = ".1"
}

variable "elasticache_redis_alarm_threshold_replication_lag_high" {
  type        = string
  description = "Critical Alert Threshhold for Redis replication_lag utilization"
  default     = ".2"
}

variable "elasticache_redis_alarm_threshold_network" {
  type        = number
  description = "Alert Threshhold for Redis percentage of total network bandwidth use"
  default     = 80
}

# prod/test environment flags
variable "asg_prevent_auto_terminate" {
  description = "Whether to protect auto scaled instances from automatic termination"
  default     = 0
}

variable "enable_deletion_protection" {
  description = "Whether to protect against API deletion of certain resources"
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

variable "client" {
}

variable "env_name" {
}

variable "env_type" {
  type        = string
  default     = "app-sandbox"
  description = "The env_type of the application. App-Produciton, App-sandbox, Gitlab-Production, etc."

  validation {
    condition = contains(
      ["peering", "security", "telemetry", "tooling-prod", "tooling-sandbox", "app-prod", "app-staging", "app-dm", "app-dm", "app-int", "app-sandbox"]
    , var.env_type)
    error_message = "Environment Type can't be found. Please check the network_layout module for valid environment types or update the validation ruleset for new environment types."
  }
}

variable "instance_type_app" {
  default = "t3.small"
}

variable "instance_type_idp" {
  default = "t3.medium"
}

variable "instance_type_migration" {
  default = "t3.medium"
}

variable "instance_type_outboundproxy" {
  default = "t3.medium"
}

variable "instance_type_pivcac" {
  default = "t3.medium"
}

variable "instance_type_worker" {
  default = "t3.medium"
}

variable "instance_type_locust" {
  default = "t3.medium"
}

variable "use_spot_instances" {
  description = "Use spot instances for roles suitable for spot use."
  type        = number
  default     = 0
}

variable "idp_mixed_instance_config" {
  description = <<EOM
Map of instance types/weighted capacities for idp Auto Scaling Group, if using.
Will also configure mixed_instances_policy.instances_distribution settings for use
with 100% Spot instances if var.use_spot_instances == 1
EOM
  type = list(object({
    instance_type     = string
    weighted_capacity = number
  }))
  default = [ # leaving the default of [] for now
    #    {
    #      instance_type     = "t3.medium"
    #      weighted_capacity = 1
    #    },
    #    {
    #      instance_type     = "t3.large"
    #      weighted_capacity = 2
    #    },
    #    {
    #      instance_type     = "t3.xlarge"
    #      weighted_capacity = 4
    #    },
    #    {
    #      instance_type     = "t3.2xlarge"
    #      weighted_capacity = 8
    #    },
  ]
}

variable "idp_default_weight" {
  type        = number
  description = <<EOM
Default weighted value for var.instance_type_idp instances within the idp
Auto Scaling Group. Must be at least 1, with even numbers preferable thereafter.
EOM
  default     = 1
}

variable "worker_mixed_instance_config" {
  description = <<EOM
Map of instance types/weighted capacities for worker Auto Scaling Group, if using.
Will also configure mixed_instances_policy.instances_distribution settings for use
with 100% Spot instances if var.use_spot_instances == 1
EOM
  type = list(object({
    instance_type     = string
    weighted_capacity = number
  }))
  default = [ # leaving the default of [] for now
    #    {
    #      instance_type     = "t3.medium"
    #      weighted_capacity = 1
    #    },
    #    {
    #      instance_type     = "t3.large"
    #      weighted_capacity = 2
    #    },
    #    {
    #      instance_type     = "t3.xlarge"
    #      weighted_capacity = 4
    #    },
    #    {
    #      instance_type     = "t3.2xlarge"
    #      weighted_capacity = 8
    #    },
  ]
}

variable "worker_default_weight" {
  type        = number
  description = <<EOM
Default weighted value for var.instance_type_worker instances within the worker
Auto Scaling Group. Must be at least 1, with even numbers preferable thereafter.
EOM
  default     = 1
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

variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "version_info_bucket" {
}

variable "version_info_region" {
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
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

# Auto scaling group desired counts
variable "asg_idp_min" {
  default = 1
}

variable "asg_idp_desired" {
  default = 1
}

variable "asg_idp_max" {
  default = 8
}

variable "asg_app_min" {
  default = 0
}

variable "asg_app_desired" {
  default = 0
}

variable "asg_app_max" {
  default = 8
}

variable "asg_migration_min" {
  default = 0
}

variable "asg_migration_desired" {
  default = 0
}

variable "asg_migration_max" {
  default = 8
}

variable "asg_pivcac_min" {
  default = 1
}

variable "asg_pivcac_desired" {
  default = 2
}

variable "asg_pivcac_max" {
  default = 4
}

variable "asg_outboundproxy_desired" {
  default = 1
}

variable "asg_outboundproxy_min" {
  default = 1
}

variable "asg_outboundproxy_max" {
  default = 9
}

variable "asg_worker_min" {
  default = 1
}

variable "asg_worker_desired" {
  default = 1
}

variable "asg_worker_max" {
  default = 8
}

# Enables worker alarms
variable "idp_worker_alarms_enabled" {
  default     = 1
  description = "Whether to set up alarms for IDP workers"
}

variable "idp_external_service_alarms_enabled" {
  default     = 0
  description = "Whether to set up alarms for IDP external services"
}

variable "cdn_public_reporting_data_alarms_enabled" {
  default     = 0
  description = "Whether to enable alarms for the Public Reporting Data CDN"
}

variable "cdn_idp_static_assets_cloudwatch_alarms_enabled" {
  default     = 0
  description = "Whether to enable cloudwatch alarms for the IDP static assets CDN"
}

variable "cdn_idp_static_assets_newrelic_alarms_enabled" {
  default     = 0
  description = "Whether to enable newrelic alarms for the IDP static assets CDN"
}

variable "cdn_idp_static_assets_alert_threshold" {
  default     = 5
  description = "Threshold for percentage of failed CDN asset requests. Can be noisy in low-volume environments."
}

variable "idp_cpu_autoscaling_enabled" {
  default = 1
}

variable "idp_cpu_autoscaling_disable_scale_in" { # we're not ready for auto scale-in yet
  default = 1
}

variable "idp_cpu_autoscaling_target" {
  default = 40
}

variable "worker_cpu_autoscaling_enabled" {
  # Off by default due to extreme burstiness of report jobs
  default = 0
}

variable "worker_cpu_autoscaling_target" {
  # Allow workers higher CPU saturation if CPU autoscaling is on
  default = 90
}

# Several variables used by the modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref_default" {
  default     = ""
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
variable "default_ami_id_sandbox" {
  default     = "ami-0c6d4ec25e224b26c" # 2023-04-05 Ubuntu 18.04
  description = "default AMI ID for environments in the sandbox account"
}

variable "default_ami_id_prod" {
  default     = "ami-03a60496ffd805d99" # 2023-04-04 Ubuntu 18.04
  description = "default AMI ID for environments in the prod account"
}

variable "rails_ami_id_sandbox" {
  default     = "ami-0de5da0c31eedd226" # 2023-04-05 Ubuntu 18.04
  description = "AMI ID for Rails (IdP/PIVCAC servers) in the sandbox account"
}

variable "rails_ami_id_prod" {
  default     = "ami-05337650e4d4e4c8a" # 2023-04-04 Ubuntu 18.04
  description = "AMI ID for Rails (IdP/PIVCAC servers) in the prod account"
}

variable "high_priority_sns_hook" {
  description = "ARN of SNS topic for high-priority pages"
}

variable "high_priority_sns_hook_use1" {
  description = "ARN of SNS topic for high-priority pages in US-East-1"
}

variable "page_devops" {
  default     = 0
  description = "Whether to page for high-priority Cloudwatch alarms"
}

variable "in_person_slack_alarms_sns_hook" {
  default     = ""
  description = <<EOM
ARN of SNS topic for low to medium priority in-person proofing alarms.
Falls back to slack_events_sns_hook_arn if not set.
EOM
}

locals {
  secrets_bucket = join(".", [
    "login-gov.secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  acct_type = data.aws_caller_identity.current.account_id == "555546682965" ? (
  "prod") : "sandbox"

  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? (
    var.bootstrap_private_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_private_git_ref = var.bootstrap_private_git_ref != "" ? (
  var.bootstrap_private_git_ref) : "main"

  bootstrap_main_s3_ssh_key_url = var.bootstrap_main_s3_ssh_key_url != "" ? (
    var.bootstrap_main_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_main_git_ref_default = var.bootstrap_main_git_ref_default != "" ? (
  var.bootstrap_main_git_ref_default) : "stages/${var.env_name}"

  account_default_ami_id = local.acct_type == "prod" ? (
  var.default_ami_id_prod) : var.default_ami_id_sandbox
  account_rails_ami_id = local.acct_type == "prod" ? (
  var.rails_ami_id_prod) : var.rails_ami_id_sandbox

  in_person_alarm_actions         = [coalesce(var.in_person_slack_alarms_sns_hook, var.slack_events_sns_hook_arn)]
  low_priority_alarm_actions      = [var.slack_events_sns_hook_arn]
  low_priority_alarm_actions_use1 = [var.slack_events_sns_hook_arn_use1]
  high_priority_alarm_actions = var.page_devops == 1 ? [
    var.high_priority_sns_hook, var.slack_events_sns_hook_arn
  ] : [var.slack_events_sns_hook_arn]
  high_priority_alarm_actions_use1 = var.page_devops == 1 ? [
    var.high_priority_sns_hook_use1, var.slack_events_sns_hook_arn_use1
  ] : [var.slack_events_sns_hook_arn_use1]

  inventory_bucket_arn = join(".", [
    "arn:aws:s3:::login-gov.s3-inventory",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  dnssec_runbook_prefix = " - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec"
}

# These variables are used to toggle whether certain services are enabled.
#
# NOTE: These must be numbers, as terraform does not support boolean values,
# only numbers and strings.
#
# See: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

variable "alb_http_port_80_enabled" {
  default     = 1
  description = "Whether to have ALB listen on HTTP port 80 (not just HTTPS 443)"
}

variable "idp_health_uri" {
  description = "Path used for load balancer health checking on the IDP - Must respond with 200 when healthy and non-200 when sick"
  type        = string
  default     = "/api/health"
}

# This is needed so the application can download its secrets

variable "app_secrets_bucket_name_prefix" {
  description = "Base name for the bucket that contains application secrets"
  default     = "login-gov-app-secrets"
}

# This variable is used to allow access to 80/443 on the general internet
# Set it to "0.0.0.0/0" to allow access
variable "outbound_subnets" {
  #default = ["0.0.0.0/0"]
  #default = ["127.0.0.1/32"] # use localhost as hack since TF doesn't handle empty list well
  default = ["172.16.32.0/22"]
  type    = list(string)
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
}

# This is useful for granting a foreign environment's idp role access to this environment's KMS key
variable "db_restore_role_arns" {
  default     = []
  description = "Name of role used to restore db data to another env (e.g. arn:aws:iam::555546682965:role/dm_idp_iam_role)"
}

variable "slack_events_sns_hook_arn" {
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
}

variable "slack_events_sns_hook_arn_use1" {
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack from US-East-1"
}


# KMS Event Matching settings
variable "kms_log_kinesis_shards" {
  description = "Number of shards to provision in Kinesis datastream for kms logging"
  default     = 1
}

variable "kms_log_alerts_enabled" {
  description = "Set to false to avoid sending KMS match alerts to Slack/SNS"
  type        = bool
  default     = true
}

variable "kms_log_kinesis_retention_hours" {
  description = "Hours to retain data in Kinesis - Min is 24 and max is 168"
  type        = number
  default     = 24
}

variable "kms_log_ct_queue_message_retention_seconds" {
  description = "Number of seconds a message will remain in the queue"
  type        = number
  default     = 345600 # 4 days
}

variable "kms_log_dynamodb_retention_days" {
  description = "Number of days to retain kms log records in DynamoDB"
  type        = number
  default     = 365
}

variable "kms_log_kmslog_lambda_debug" {
  description = "Whether to run the kms logging lambdas in debug mode in this account"
  type        = bool
  default     = false
}

variable "kms_log_lambda_identity_lambda_functions_gitrev" {
  description = "This is gross and temporary, but we need to be able to switch KMS matcher code without a new rev of identity-terraform"
  type        = string
  default     = "1815de9b0893548876138e7086391e210cc85813"
}


variable "newrelic_alerts_enabled" {
  description = "turn on common newrelic alerting services.  Required if any other newrelic stuff is enabled."
  default     = 0
}
variable "staticsite_newrelic_alerts_enabled" {
  description = "this should only be set in the prod environment, as it creates monitors for the static site"
  default     = 0
}
variable "idp_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to alert on idp problems"
  default     = 0
}

variable "new_relic_pager_alerts_enabled" {
  default     = 0
  type        = number
  description = "Enables OpsGenie alerts for NewRelic alarms"

}
variable "idp_in_person_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to alert on in-person proofing idp problems"
  default     = 0
}

variable "idp_enduser_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to alert on enduser idp problems"
  default     = 0
}
variable "dashboard_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to alert during business hours on dashboard problems"
  default     = 0
}


variable "opsgenie_key_file" {
  description = "the name of the file in the secrets/common bucket to use for sending opsgenie alerts in newrelic for this environment"
  default     = "opsgenie_low_apikey" # This sends alerts during business hours
  # default = "opsgenie_apikey"   # This sends alerts 7x24
}

## CloudWatch Alarm Defaults
variable "pivcac_low_traffic_alert_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we alert"
  default     = 5
}

variable "pivcac_mfa_low_alert_threshold" {
  description = "Minimum number of successful PIV/CAC MFA sign ins per 60 minutes"
  type        = number
  default     = 0
}

variable "proofing_low_alert_threshold" {
  description = "Minimum number of successful proofs in an hour"
  type        = number
  default     = 0
}

variable "sms_error_rate_alert_threshold" {
  description = "If more than this number of SMS attempts error in a minute, we alert"
  default     = 1
}

variable "sms_mfa_low_alert_threshold" {
  description = "Minimum number of successful SMS MFA sign ins per 10 minutes"
  type        = number
  default     = 0
}

variable "sms_mfa_low_success_alert_threshold" {
  description = "Minimum success rate of SMS MFA sign ins per 10 minutes"
  type        = number
  default     = 0
}

variable "sms_send_rate_alert_threshold" {
  description = "If more than this number of SMS deliveries is exeeded in a minute, we alert"
  default     = 100
}

variable "sms_high_retry_percentage_threshold" {
  description = "If more than this percentage of SMS retries, send alert"
  default     = 0
}

variable "sp_return_low_alert_threshold" {
  description = "Minimum number of SP redirect initiations (SP returns) per 10 minutes"
  type        = number
  default     = 0
}

variable "user_registration_low_alert_threshold" {
  description = "Minimum number of user registrations (sign ups) per 10 minutes"
  type        = number
  default     = 0
}

variable "voice_error_rate_alert_threshold" {
  description = "If more than this number of voice attempts error in a minute, we alert"
  default     = 1
}
variable "voice_send_rate_alert_threshold" {
  description = "If more than this number of voice OTP deliveries is exeeded in a minute, we alert"
  default     = 10
}

variable "web_low_traffic_alert_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we alert"
  default     = 10
}

variable "web_low_traffic_warn_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we warn"
  default     = 20
}


variable "keep_legacy_bucket" {
  description = "Whether or not to preserve the login-gov-ENV-logs bucket. Should only be used in staging and prod."
  default     = false
}

# DocAuth / Vendors

variable "doc_capture_secrets" {
  description = "Map of key name/descriptions of empty SSM parameter store items to create"
  type        = map(string)
  default = {
    aamva_private_key                  = "AAMVA private key",
    aamva_public_key                   = "AAMVA public key",
    acuant_assure_id_password          = "Acuant AssureID password",
    acuant_assure_id_subscription_id   = "Accuant AssureID subscription ID",
    acuant_assure_id_url               = "Acuant AssureID URL",
    acuant_assure_id_username          = "Acuant AssureID username",
    acuant_facial_match_url            = "Acuant facial match URL",
    acuant_passlive_url                = "Acuant passlive URL",
    acuant_timeout                     = "Acuant timeout",
    address_proof_result_token         = "Address proof result API authentication token, corresponds to address_proof_result_lambda_token in IDP",
    document_proof_result_token        = "Document proof result API authentication token, corresponds to document_proof_result_lambda_token in IDP",
    lexisnexis_account_id              = "LexisNexis account ID",
    lexisnexis_base_url                = "LexisNexis base URL",
    lexisnexis_instant_verify_workflow = "LexisNexis InstantVerify workflow name",
    lexisnexis_password                = "LexisNexis password",
    lexisnexis_phone_finder_workflow   = "LexisNexis PhoneFinder workflow name",
    lexisnexis_request_mode            = "LexisNexis request mode",
    lexisnexis_username                = "LexisNexis username",
    resolution_proof_result_token      = "Resolution proof result API authentication token, corresponds to resolution_proof_result_lambda_token in IDP",
  }
}

variable "doc_auth_vendors" {
  type        = map(string)
  description = "Map of DocAuth vendors : metric names (for exception rate alarms)"
  default     = {}
}

variable "external_service_alarms" {
  type = map(object({
    long_name          = string
    tps_max            = optional(number)
    tps_threshold_pct  = optional(number, 80)
    latency_percentile = optional(number)
    latency_threshold  = optional(number)
  }))
  description = "List/Map of DocAuth vendors + configs for CloudWatch alarms"
  default     = {}
}

variable "tf_slack_channel" {
  description = "Slack channel to send events to."
  default     = "#login-personal-events"
}

variable "slack_oncall_groups" {
  type        = list(string)
  description = <<EOM
Slack group handle(s) for 'prod'-environment Oncall response. Add to the Description
of a CloudWatch alert to ping said handle(s) via an OpsGenie message in Slack.

NOTE: Must be added AFTER a valid 'Runbook:' line (e.g. with a URL attached)
to prevent the SNSToSlackNotifier from triggering a duplicate notification.
EOM
  default = [
    "login-devops-oncall",
    "login-appdev-oncall"
  ]
}

variable "slack_proofing_groups" {
  type        = list(string)
  description = <<EOM
Slack group handle(s) for Vendor Proofing Oncall. Add to the Description
of a CloudWatch alert in order to ping said handle(s) via the SNSToSlackNotifier.
EOM
  default = [
    "login-oncall-ada"
  ]
}

variable "gitlab_enabled" {
  description = "whether to turn on the privatelink to gitlab so that systems can git clone and so on"
  type        = bool
  default     = false
}

variable "gitlab_servicename" {
  description = "the service_name of the gitlab privatelink"
  default     = ""
}

variable "gitlab_hostname" {
  description = "name to write into the internal dns zone"
  default     = "gitlab"
}

variable "gitlab_runner_enabled" {
  description = "whether to turn on a gitlab runner for this environment"
  type        = bool
  default     = false
}

variable "gitlab_configbucket" {
  description = "should be used to override where the gitlab server's config bucket is so that the runner knows where to get the runner token"
  default     = ""
}

variable "gitlab_ecr_repo_accountid" {
  description = "the AWS account ID where it's gitlab lives, so it knows what ECR to pull from"
  default     = "217680906704" # prod
}

variable "idp_ial2_sp_dashboards" {
  type = map(object({
    name     = string
    issuer   = string
    protocol = string
    agency   = string
  }))
  description = "Map of values for widgets on IAL2 SP dashboard"
  default     = {}
}

variable "idp_sp_dashboards" {
  type = map(object({
    name   = string
    issuer = string
    agency = string
  }))
  description = "Map of values for widgets on SP dashboard"
  default     = {}
}

variable "soc_destination_arn" {
  type    = string
  default = "arn:aws:logs:us-west-2:752281881774:destination:elp-os-lg" #Pointing to  SOC arn. Please check before deploying
}

variable "cloudwatch_log_group_name" {
  type = map(string)
  default = {
    # map of logs to be shipped,with filter pattern, key is log name, value is filter pattern with " " denoting send all events
  }
}

variable "send_cw_to_soc" {
  type    = string
  default = "0"
}

variable "enable_cloudwatch_slos" {
  type    = bool
  default = true
}

variable "sli_interesting_latency_threshold" {
  description = "Threshold in seconds for latency on interesting paths"
  type        = number
  default     = 0.1
}

variable "low_memory_alert_enabled" {
  description = "set this to 1 if you want to alert on low memory alert in New Relic"
  default     = 0
}

variable "memory_free_threshold_byte" {
  description = "Low memory threshold in bytes for New Relic"
  default     = "524288000" #500 MB
}

variable "ssm_session_timeout" {
  description = <<EOM
REQUIRED. Amount of time (in minutes) of inactivity to allow before an
SSM session ends. Defaults to 15 minutes.
EOM
  type        = number
  default     = 15
}

variable "enable_usps_status_updates" {
  type        = bool
  description = <<EOM
Enables recieving emails from USPS for notification updates on in-person proofing.
EOM
  default     = false
}

variable "privatedir" {
  description = "where identity-devops-private lives.  Used for the version_info.sh script"
  default     = ""
}

variable "cloudfront_s3_cache_paths" {
  description = <<EOM
The list of paths to serve from the static content s3 bucket,
should contain /packs/* and /assets/* to not break static content
EOM
  type = list(object({
    path            = string
    caching_enabled = bool
  }))
  default = [
    {
      path            = "/packs/*"
      caching_enabled = true
    },
    {
      path            = "/assets/*"
      caching_enabled = true
    },
    {
      path            = "/5xx-codes/*"
      caching_enabled = false
    },
    {
      path            = "/maintenance/*"
      caching_enabled = false
    }
  ]
}

variable "cloudfront_custom_error_responses" {
  description = <<EOM
List of custom error responses to show to the end user
instead of just an error code.
EOM
  type = list(object({
    ttl                = number
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = [
    {
      ttl                = 0
      error_code         = 504
      response_code      = 504
      response_page_path = "/5xx-codes/503.html"
    },
    {
      ttl                = 0
      error_code         = 503
      response_code      = 503
      response_page_path = "/5xx-codes/503.html"
    },
    {
      ttl                = 0
      error_code         = 502
      response_code      = 502
      response_page_path = "/5xx-codes/503.html"
    }
  ]
}

variable "enable_cloudfront_maintenance_page" {
  description = <<EOM
Enables a maintenance page infront of idp servers
and routes all traffic to that until disabled
EOM
  type        = bool
  default     = false
}

variable "cloudfront_custom_pages" {
  description = <<EOM
List of custom pages to populate into the static S3 bucket used by CloudFront for
custom error/maintenance handling. Format is {<s3-bucket-key> = <local-file-source>}"
EOM
  type        = map(string)
  default = {
    "5xx-codes/503.html"           = "./custom_pages/503.html",
    "maintenance/maintenance.html" = "./custom_pages/maintenance.html"
  }
}

variable "idp_cloudfront_waf_enabled" {
  description = <<EOM
Enable or disable WAFv2 rule association with idp CloudFront distribution.
Requires a corresponding, active environment/config in the terraform/waf directory.
EOM
  type        = bool
  default     = false
}

variable "idp_pii_spill_patterns" {
  type        = list(string)
  description = "List of strings used in proofing with smoke tests - These should never appear in logs!"
  # Suggested test data from https://developers.login.gov/testing/#data-testing as
  # well as common test fixture data
  default = [
    # First Names
    "Susan",
    "FAKEY",
    # Last Names
    "MCFAKERSON",
    # Addresses
    "1 Microsoft Way",
    "Bayside",
    # Birthdates
    "10/06/1938", # Fake birthdate
    "1938-10-06", # Alt fake birthdate
    # Phones
    "314-555-1212" # Fake phone
  ]
}

variable "events_log_lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type        = number
  default     = 512
}

variable "events_log_lambda_ephemeral_storage" {
  description = "Used to expand the total amount of Ephemeral storage available, beyond the default amount of 512MB"
  type        = number
  default     = 512
}

variable "events_log_lambda_timeout" {
  description = "Timeout for Lambda function"
  type        = number
  default     = 30
}

variable "destroy_firehose_bucket" {
  description = <<EOM
Whether or not to allow the Kinesis Firehose stream bucket to be destroyed
with objects still present in it.
Defaults to true; MUST be set to false in upper environments!
EOM
  type        = bool
  default     = true
}

variable "enable_loadtesting" {
  type        = bool
  description = "Feature Flag for Locust loadtesting hosts and related infrastructure"
  default     = false
}

variable "asg_locust_worker_desired" {
  default = 0
}

variable "asg_locust_leader_desired" {
  default = 0
}

variable "asg_locust_worker_max" {
  default = 8
}

variable "use_lor_algorithm" {
  description = "Use Least Outstanding Requests algorithm for Application Load Balancer load balancing requests"
  type        = bool
  default     = false
}

variable "cloudfront_http_version" {
  description = "Http version supported by Cloudfront distribution. Valid values are either http2 or http2and3"
  default     = "http2and3"
}

variable "sli_uninteresting_uris" {
  description = "Uninteresting URIs that may dilute an SLI due to their high frequency and relatively cheap cost."
  default = [
    "/api/health",
    "/apple-touch-icon.png",
    "/es",
    "/favicon-16x16.png",
    "/favicon-32x32.png",
    "/fr",
    "/health_check",
    "/manifest.json"
  ]
}

variable "escrow_content_expiration" {
  description = "Expiration of documents that are pushed to the escrow s3 bucket in days"
  type        = string
  default     = 730
}

variable "worker_sg_ingress_permitted_ips" {
  description = "IP addresses permitted access to HTTP(s) health checks for worker instances"
  type        = list(string)
  default     = ["159.142.0.0/16"]
}

variable "attempts_api_low_success_alarm_threshold" {
  description = "Minimum number of IRS Attempts API Event calls per 90 minutes"
  type        = number
  default     = 0
}

variable "minutes_since_ipp_enrollment_established_alarm_threshold" {
  description = "Maximum number of minutes after which an established USPS IPP enrollment is expected to expire"
  type        = number
  default     = 43560 # 30 days + 6 hours
}

variable "minutes_since_ipp_enrollment_status_check_completed_alarm_threshold" {
  description = "Maximum number of minutes expected between completed status checks for an established USPS IPP enrollment"
  type        = number
  default     = 360 # 6 hours
}

variable "enrollments_expiration_alarm_threshold" {
  description = "Large number of pending enrollments are set to expire"
  type        = number
  default     = 33120 # 23 days (expected expiration ~30 days)
}

variable "long_usps_proofing_job_threshold" {
  description = "Maximum expected runtime in seconds for the USPS proofing job"
  type        = number
  default     = 1200 # 20 minutes
}

variable "low_sp_oidc_token_enabled_sps" {
  description = "A mapping of client IDs and thresholds for OIDC token success per hour."
  type = map(object({
    sp_name   = string # Name of the Service Provider / Application
    client_id = string # URN for the Service Provider
    threshold = number # Minimum successful calls per/window (5 minutes)
  }))
  default = {}
}

variable "allow_nessus_external_scanning" {
  description = "Enables Nessus to externally scan data-services subnet resources"
  type        = bool
  default     = false
}

variable "enable_redis_cache_instance" {
  description = "Enables the creation and monitoring of redis cache instance"
  type        = bool
  default     = false
}

variable "enable_redis_ratelimit_instance" {
  description = "Enables the creation and monitoring of redis ratelimit instance"
  type        = bool
  default     = false
}

variable "waf_alerts_enabled" {
  description = "set this to true if you want to alert on WAF problems"
  type        = number
  default     = 0
}
