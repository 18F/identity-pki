variable "force_destroy_app_static_bucket" {
  description = "Allow destruction of app static bucket even if not empty"
  type        = bool
  default     = true
}

variable "force_destroy_idp_static_bucket" {
  description = "Allow destruction of IdP static bucket even if not empty"
  type        = bool
  default     = true
}

variable "app_static_bucket_cross_account_access" {
  description = "Source roles from other accounts allowed access to the bucket"
  type        = list(string)
  default     = []
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

variable "route53_id" {
}

variable "apps_enabled" {
  type        = number
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

variable "instance_type_env_runner" {
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

# The following AMIs should be built at the same time and identical, even
# though they will have different IDs. They should be updated here at the same
# time, and then released to environments in sequence.

#### us-west-2

variable "base_ami_sandbox_uw2" {
  default     = "ami-0946ba32da9ac10fe" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'base' hosts (outboundproxy) in the sandbox account
EOM
}

variable "base_ami_prod_uw2" {
  default     = "ami-0fb45f6f2ed5d42d2" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'base' hosts (outboundproxy) in the prod account
EOM
}

variable "rails_ami_sandbox_uw2" {
  default     = "ami-01e8a4585607d75b3" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'rails' hosts (IdP/PIVCAC servers) in the sandbox account
EOM
}

variable "rails_ami_prod_uw2" {
  default     = "ami-0ae1450763ecf4602" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-west-2 AMI ID for 'rails' hosts (IdP/PIVCAC servers) in the prod account
EOM
}

variable "ami_id_map_uw2" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default = {
    #app           = "ami-049373819feac677b"
    #idp           = "ami-049373819feac677b"
    #migration     = "ami-049373819feac677b"
    #outboundproxy = "ami-0a64068f10aca88cf"
    #pivcac        = "ami-049373819feac677b"
    #worker        = "ami-049373819feac677b"
  }
}

##### us-east-1

variable "base_ami_sandbox_ue1" {
  default     = "ami-003d9273d49cc2fed" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-east-1 AMI ID for 'base' hosts (outboundproxy) in the sandbox account
EOM
}

variable "base_ami_prod_ue1" {
  default     = "" # 2023-07-11 Ubuntu 20.04
  description = <<EOM
us-east-1 AMI ID for 'base' hosts (outboundproxy) in the prod account
EOM
}

variable "rails_ami_sandbox_ue1" {
  default     = "ami-016b51ca47187fb48" # 2024-10-22 Ubuntu 20.04
  description = <<EOM
us-east-1 AMI ID for 'rails' hosts (IdP/PIVCAC servers) in the sandbox account
EOM
}

variable "rails_ami_prod_ue1" {
  default     = "" # 2023-07-11 Ubuntu 20.04
  description = <<EOM
us-east-1 AMI ID for 'rails' hosts (IdP/PIVCAC servers) in the prod account
EOM
}

variable "ami_id_map_ue1" {
  type        = map(string)
  description = <<EOM
Custom map of host types to us-east-1 AMI IDs. Values, if set, will override the
account default 'base' and 'rails' AMI IDs to create hosts with in the specified env.
EOM
  default = {
    #app           = "ami-0a1509723018279c7"
    #idp           = "ami-0a1509723018279c7"
    #migration     = "ami-0a1509723018279c7"
    #outboundproxy = "ami-0545f343c13472f0c"
    #pivcac        = "ami-0a1509723018279c7"
    #worker        = "ami-0a1509723018279c7"
  }
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

variable "doc_auth_slack_alarms_sns_hook" {
  default     = ""
  description = <<EOM
ARN of SNS topic for low to medium priority in-person doc auth proofing alarms.
Falls back to slack_events_sns_hook_arn if not set.
EOM
}

locals {
  secrets_bucket = join(".", [
    "login-gov.secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  secrets_bucket_ue1 = join(".", [
    "login-gov.secrets",
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  acct_type = data.aws_caller_identity.current.account_id == "555546682965" ? (
  "prod") : "sandbox"

  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? (
    var.bootstrap_private_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_private_git_ref = var.bootstrap_private_git_ref != "" ? (
  var.bootstrap_private_git_ref) : "main"

  bootstrap_private_s3_ssh_key_url_ue1 = "s3://${local.secrets_bucket_ue1}/common/id_ecdsa.id-do-private.deploy"

  bootstrap_main_s3_ssh_key_url = var.bootstrap_main_s3_ssh_key_url != "" ? (
    var.bootstrap_main_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_main_git_ref_default = var.bootstrap_main_git_ref_default != "" ? (
  var.bootstrap_main_git_ref_default) : "stages/${var.env_name}"

  bootstrap_main_s3_ssh_key_url_ue1 = "s3://${local.secrets_bucket_ue1}/common/id_ecdsa.identity-devops.deploy"

  account_default_ami_id = local.acct_type == "prod" ? (
  var.base_ami_prod_uw2) : var.base_ami_sandbox_uw2
  account_rails_ami_id = local.acct_type == "prod" ? (
  var.rails_ami_prod_uw2) : var.rails_ami_sandbox_uw2

  base_ami_id_ue1 = local.acct_type == "prod" ? (
  var.base_ami_prod_ue1) : var.base_ami_sandbox_ue1
  rails_ami_id_ue1 = local.acct_type == "prod" ? (
  var.rails_ami_prod_ue1) : var.rails_ami_sandbox_ue1

  in_person_alarm_actions              = [coalesce(var.in_person_slack_alarms_sns_hook, var.slack_events_sns_hook_arn)]
  doc_auth_alarm_actions               = [coalesce(var.doc_auth_slack_alarms_sns_hook, var.slack_events_sns_hook_arn)]
  low_priority_alarm_actions           = [var.slack_events_sns_hook_arn]
  low_priority_alarm_actions_use1      = [var.slack_events_sns_hook_arn_use1]
  low_priority_dw_alarm_actions        = [var.slack_events_sns_hook_arn, var.slack_dw_events_sns_hook_arn]
  moderate_priority_alarm_actions      = [var.slack_alarms_sns_hook_arn]
  moderate_priority_alarm_actions_use1 = [var.slack_alarms_sns_hook_arn_use1]

  high_priority_alarm_actions = var.page_devops == 1 ? flatten([
    var.high_priority_sns_hook,
    var.slack_alarms_sns_hook_arn
  ]) : [var.slack_alarms_sns_hook_arn]
  high_priority_alarm_actions_use1 = var.page_devops == 1 ? flatten([
    var.high_priority_sns_hook_use1,
    var.slack_alarms_sns_hook_arn_use1
  ]) : [var.slack_alarms_sns_hook_arn_use1]

  inventory_bucket_arn = join(".", [
    "arn:aws:s3:::login-gov.s3-inventory",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  incident_manager_teams = flatten([
    [
    for k, v in yamldecode(file("../master/global/users.yaml"))["oncall_teams"] : k],
    var.idp_enduser_newrelic_alerts_enabled == 1 ? ["appdev_enduser"] : []
  ])
  dnssec_runbook_prefix = " - https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-DNS#dnssec"

  # defines which VPC service endpoints to create; always create all endpoints for prod envs
  aws_endpoints = yamldecode(file("./vpc_endpoints.yaml"))[
    local.acct_type == "prod" ? "all" : (
      var.enable_all_vpc_endpoints ? "all" : "required"
    )
  ]

  vpc_endpoints_no_proxy_hosts = sort(flatten([for region in compact(["us-west-2", var.enable_us_east_1_vpc ? "us-east-1" : ""]) : [for k, v in local.aws_endpoints : "${k}.${region}.amazonaws.com"]]))

  no_proxy_hosts = join(",", concat(
    # These hosts should always be no_proxy. The latter set of hosts are added depending on
    # which VPC endpoints are created, and whether or not us-east-1 VPC creation is enabled.
    # VPC endpoint traffic should skip the outbound proxy.
    [
      "localhost",
      "127.0.0.1",
      "169.254.169.254",
      "169.254.169.123",
      ".login.gov.internal",
      "metadata.google.internal"
    ],
    local.vpc_endpoints_no_proxy_hosts
  ))

  data_warehouse_lambda_alerts_runbooks = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#lambda-alerts"
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
  description = "ARN of SNS topic that will notify the #login-events/#login-otherevents channels in Slack"
}

variable "slack_events_sns_hook_arn_use1" {
  description = "ARN of SNS topic that will notify the #login-events/#login-otherevents channels in Slack from US-East-1"
}

variable "slack_dw_events_sns_hook_arn" {
  description = "ARN of SNS topic that will notify the #login-data-warehouse-otherevents/#login-data-warehouse-events channels in Slack"
  default     = ""
}

variable "slack_alarms_sns_hook_arn" {
  description = "ARN of SNS topic that will notify the #login-alarms channel in Slack"
}

variable "slack_alarms_sns_hook_arn_use1" {
  description = "ARN of SNS topic that will notify the #login-alarms channel in Slack from US-East-1"
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

variable "kms_log_ct_requeue_concurrency" {
  description = "Defines the number of requeue lambda's to initiate every hour"
  type        = number
  default     = 1
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

variable "kms_log_cw_processor_memory_size" {
  description = "Defines the amount of memory in MB the KMS Log CloudWatch Processor can use at runtime"
  type        = number
  default     = 128
  validation {
    condition     = var.kms_log_cw_processor_memory_size >= 128 && var.kms_log_cw_processor_memory_size <= 10240
    error_message = "The kms_log_cw_processor_memory_size must be between the values 512 MB and 10240 MB"
  }
}

variable "kms_log_cw_processor_storage_size" {
  description = "Defines the amount of ephemeral storage (/tmp) in MB available to the KMS Log CloudWatch Processor"
  type        = number
  default     = 512
  validation {
    condition     = var.kms_log_cw_processor_storage_size >= 512 && var.kms_log_cw_processor_storage_size <= 10240
    error_message = "The kms_log_cw_processor_storage_size must be between the values 512 MB and 10240 MB"
  }
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
  description = "Enables paging alerts for NewRelic alarms"

}
variable "idp_in_person_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to alert on in-person proofing idp problems"
  default     = 0
}

variable "idp_doc_auth_newrelic_alerts_enabled" {
  description = "set this to 1 if you want to enable in-person proofing doc auth alerting"
  default     = 0
}

variable "idp_no_healthy_hosts_alarm_enabled" {
  description = "set this to 1 if you want to a high alert when there are no healthy IDP hosts"
  default     = 0
}

variable "idp_proofing_javascript_error_new_relic_alerts_enabled" {
  description = "set this to 1 if you want to enable proofing javascript error alerting"
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

variable "proofing_pageview_duration_alert_threshold" {
  description = "If pageviews in proofing are too slow, we alert"
  default     = 10
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

variable "sms_mfa_low_success_alert_critical_threshold" {
  description = "Minimum success rate of SMS MFA sign ins per 10 minutes to page on-callers for"
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
  description = <<EOM
Whether or not to preserve the login-gov-ENV-logs bucket.
Should only be set to 'true' in upper environments.
EOM
  default     = false
}

variable "keep_log_cache_bucket" {
  description = <<EOM
Whether or not to preserve the login-gov-log-cache-ENV bucket, previously used
with the send_logs_to_s3 module/cw-kinesis-s3-idp-events Subscription Filter.
Should only be set to 'true' in upper environments.
EOM
  default     = false
}

# DocAuth / Vendors

variable "idv_high_proofing_resolution_result_missing_threshold" {
  description = "Threshold of how many events need to occur within the period to trigger the alert"
  default     = 3
}

variable "idv_unexpected_face_match_errors_threshold" {
  type        = number
  description = "Threshold of how many events need to occur within the period to trigger the alert"
  default     = 1
}

variable "doc_auth_vendors" {
  type = map(object({
    long_name            = string
    evaluation_periods   = optional(number, 1)
    runbook_url          = optional(string, "")
    slack_oncall_handles = optional(list(string), [])
  }))
  description = <<EOM
List of DocAuth vendors mapped to long names, optionally with separately-configured
values for evaluation_periods and runbook_url, as used in the
aws_cloudwatch_metric_alarm.doc_auth_vendor_exception_rate resource.
EOM
  default = {
    "aamva" = {
      long_name            = "AAMVA",
      evaluation_periods   = 2,
      runbook_url          = "AAMVA-DLDV-outage",
      slack_oncall_handles = ["@login-oncall-ada"]
    }
    "iv" = {
      long_name            = "Instant Verify",
      runbook_url          = "LexisNexis-Instant-Verify-outage",
      slack_oncall_handles = ["@login-oncall-ada"]
    }
    "pinpoint" = {
      long_name            = "Pinpoint",
      slack_oncall_handles = []
    }
    "trueid" = {
      long_name            = "TrueID",
      runbook_url          = "LexisNexis-TrueID-outage",
      slack_oncall_handles = ["@login-oncall-timnit", "@login-oncall-ada"]
    }
  }
}

variable "external_service_alarms" {
  type = map(object({
    long_name            = string
    tps_max              = optional(number)
    tps_threshold_pct    = optional(number, 80)
    latency_percentile   = optional(number)
    latency_threshold    = optional(number)
    slack_oncall_handles = optional(list(string), [])
  }))
  description = "List/Map of DocAuth vendors + configs for CloudWatch alarms"
  default = {
    "lexis_nexis_instant_verify" = {
      long_name            = "LN Instant Verify",
      latency_percentile   = 90,
      latency_threshold    = 10
      slack_oncall_handles = ["@login-oncall-ada"]
    },
    "lexis_nexis_phone_finder" = {
      long_name            = "LN Phone Finder",
      latency_percentile   = 90,
      latency_threshold    = 10
      slack_oncall_handles = ["@login-oncall-ada"]
    },
    "aamva_verification" = {
      long_name            = "AAMVA DLDV",
      tps_max              = 8
      slack_oncall_handles = ["@login-oncall-ada"]
    }
  }
}

variable "tf_slack_channel" {
  description = "Slack channel to send events to."
  default     = "#login-personal-events"
}

variable "slack_oncall_groups" {
  type        = list(string)
  description = <<EOM
Slack group handle(s) for 'prod'-environment Oncall response. Add to the Description
of a CloudWatch alert to ping said handle(s) via a message in Slack.

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

variable "slack_doc_auth_groups" {
  type        = list(string)
  description = <<EOM
Slack group handle(s) for doc auth specific alerts. Add to the Description
of a CloudWatch alert in order to ping said handle(s) via the SNSToSlackNotifier.
EOM
  default = [
    "login-timnit-engineers"
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

variable "idp_dashboard_filter_sps" {
  type = list(object({
    name    = string
    issuers = list(string)
  }))
  description = "List of SPs that can be added as filters to dashboards"
  default     = []
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

variable "ssm_access_enabled" {
  description = <<EOM
Whether or not to attach SSM access policies to IAM roles.
Can set to 'false' for testing in EKS-based environments.
EOM
  type        = bool
  default     = true
}

variable "enable_usps_status_updates" {
  type        = bool
  description = <<EOM
Enables recieving emails from USPS for notification updates on in-person proofing.
EOM
  default     = false
}

variable "allowed_usps_status_update_source_email_addresses" {
  type        = list(string)
  description = "The allowed source email addresses. If empty, allows all email addresses."
  default     = []
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

variable "cloudfront_app_s3_cache_paths" {
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

variable "enable_app_cloudfront_maintenance_page" {
  description = <<EOM
Enables a maintenance page infront of idp servers
and routes all traffic to that until disabled
EOM
  type        = bool
  default     = false
}

variable "cloudfront_read_timeout" {
  description = "Specifies the amount of seconds CloudFront will wait for a response from the idp"
  type        = number
  default     = 30

  validation {
    condition     = var.cloudfront_read_timeout >= 1
    error_message = "The minimum cloudfront read timeout is 1 second."
  }

  validation {
    condition     = var.cloudfront_read_timeout <= 60
    error_message = "The default maximum cloudfront read timeout is 60 seconds. To exceed this, please contact AWS Support Center."
  }
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

variable "app_cloudfront_waf_enabled" {
  description = <<EOM
Enable or disable WAFv2 rule association with app CloudFront distribution.
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

variable "worker_sg_ingress_permitted_ips" {
  description = "IP addresses permitted access to HTTP(s) health checks for worker instances"
  type        = list(string)
  default     = ["159.142.0.0/16"]
}

variable "minutes_since_ipp_enrollment_established_alarm_threshold" {
  description = "Maximum number of minutes after which an established USPS IPP enrollment is expected to expire"
  type        = number
  default     = 45360 # 31 days and 12 hours
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

variable "in_person_high_usps_proofing_job_error_rate" {
  description = "Maximum expected error rate for USPS proofing job"
  type        = number
  default     = 10 # 10 percent enrollments errored out of enrollments checked
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

variable "enable_redis_notifications" {
  description = "Enables elasticache notification on all redis instances"
  type        = bool
  default     = false
}

variable "waf_alerts_enabled" {
  description = "set this to true if you want to alert on WAF problems"
  type        = number
  default     = 0
}

# Disaster Recovery

variable "dr_restore_idp_db" {
  type    = bool
  default = false
}

variable "dr_snapshot_identifier" {
  type        = string
  description = "Identifier of the database snapshot for snapshot recovery"
  default     = ""
}

variable "dr_restore_type" {
  type    = string
  default = ""
}

variable "dr_restore_to_time" {
  type        = string
  description = "Timestamp for point-in-time recovery (2023-04-21T12:00:00Z)"
  default     = ""
}

variable "enable_us_east_1_vpc" {
  type        = bool
  default     = false
  description = "Whether or not to create the VPC module for us-east-1"
}

variable "us_east_1_vpc_cidr_block" { # 172.17.32.0   - 172.17.35.255
  default     = "172.17.32.0/22"
  description = "Primary CIDR for the new vpc in us-east-1 region"
}

variable "enable_all_vpc_endpoints" {
  type        = bool
  default     = false
  description = "Whether or not to create all of the VPC endpoints. This must be enabled in ATO environments."
}

variable "enable_tls_and_cipher_headers" {
  type        = bool
  default     = true
  description = "Enables adding x-amzn-tls-version and x-amzn-tls-cipher-suite headers on client requests"
}

variable "enable_us_east_1_infra" {
  type        = bool
  default     = false
  description = "Flag to create us-east-1 host infrastructure"
}

variable "replicate_keymaker_key" {
  type        = bool
  default     = false
  description = <<EOM
Whether or not to make a replica key for the multi-region keymaker key
in the us-east-1 region.
EOM
}

variable "low_sms_mfa_setup_success_country_codes" {
  type        = list(string)
  default     = []
  description = <<EOM
Country codes to alarm on for low sms MFA setup success
EOM
}

variable "sms_mfa_setup_success_threshold" {
  type        = number
  default     = 50
  description = <<EOM
Threshold for percentage of successful confirmations OTPs relative to the number of confirmation/setup OTPs sent.
If less than 50% of OTPs sent for confirming new phone numbers are converted successfully, it may indicate abuse or telephony problems.
EOM
}

variable "prevent_tf_log_deletion" {
  type        = bool
  default     = false
  description = <<EOM
Whether or not to allow Terraform to ACTUALLY destroy the CloudWatch Log Groups
defined in terraform/app/cloudwatch-log.tf (vs. simply removing them from state).
EOM
}

variable "logarchive_acct_id" {
  type        = string
  description = <<EOM
ID of the 'logarchive' AWS account containing CloudWatch Log Destinations and
Kinesis Data/Firehose Streams, which CloudWatch Subscription Filters
created via the logarchive_subscription_filters module(s) will send to.
LEAVE BLANK to prevent the creation of said Subscription Filters.
EOM
  default     = ""
  validation {
    condition     = length(var.logarchive_acct_id) == 0 || length(var.logarchive_acct_id) == 12
    error_message = "The logarchive_acct_id must be a valid AWS account id."
  }
}
variable "incident_manager_enabled" {
  description = "Set this to true to enable AWS Incident Manager for an environment."
  type        = number
  default     = 0
}

variable "analytics_account_id" {
  type        = string
  default     = "487317109730"
  description = "The associated analytics account to use. Defaults to analytics-sandbox"
}

variable "start_cw_export_task_lambda_schedule" {
  type        = string
  default     = "rate(1 day)"
  description = "Determines the schedule to execute the export lambda. Supports rate expression and cron expression"
}

variable "start_dms_task_lambda_schedule" {
  type        = string
  default     = "rate(1 day)"
  description = "Determines the schedule to execute the export lambda. Supports rate expression and cron expression"
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

variable "transform_cw_export_memory_size" {
  description = "Defines the amount of memory in MB the transform_cw_export lambda can use at runtime"
  type        = number
  default     = 128
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
