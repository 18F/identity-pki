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
  description = "Enable CloudFront distribution serving from S3 bucket (enable_idp_static_bucket must be true)"
  type        = bool
  default     = false
}

variable "idp_static_bucket_cross_account_access" {
  description = "Source roles from other accounts allowed access to the bucket"
  type        = list(string)
  default     = []
}

# unallocated: "172.16.33.96/28"   # 172.16.33.96  - 172.16.33.111
# unallocated: "172.16.33.112/28"  # 172.16.33.112 - 172.16.33.115
variable "db1_subnet_cidr_block" { # 172.16.33.32 - 172.16.33.47
  default = "172.16.33.32/28"
}

variable "db2_subnet_cidr_block" { # 172.16.33.48 - 172.16.33.63
  default = "172.16.33.48/28"
}

variable "db3_subnet_cidr_block" { # 172.16.33.64 - 172.16.33.79
  default = "172.16.33.64/28"
}

variable "idp1_subnet_cidr_block" { # 172.16.33.128 - 172.16.33.159
  default = "172.16.33.128/27"
}

variable "idp2_subnet_cidr_block" { # 172.16.33.160 - 172.16.33.191
  default = "172.16.33.160/27"
}

# Reusing unused idp3 subnet - Eventually should have all 4 AZs covered
variable "alb3_subnet_cidr_block" { # 172.16.33.208 - 172.16.33.223
  default = "172.16.33.208/28"
}

variable "alb1_subnet_cidr_block" { # 172.16.33.224 - 172.16.33.239
  default = "172.16.33.224/28"
}

variable "alb2_subnet_cidr_block" { # 172.16.33.240 - 172.16.33.255
  default = "172.16.33.240/28"
}

variable "jumphost1_subnet_cidr_block" { # 172.16.32.32  - 172.16.32.47
  default = "172.16.32.32/28"
}

variable "jumphost2_subnet_cidr_block" { # 172.16.32.48  - 172.16.32.63
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
    jumphost      = 0
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

variable "elasticache_redis_node_type" {
  description = "Instance type used for redis elasticache. Changes incur downtime."

  # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
  default = "cache.t3.micro"
}

variable "elasticache_redis_engine_version" {
  description = "Engine version used for redis elasticache. Changes may incur downtime."
  default     = "5.0.6"
}

variable "elasticache_redis_parameter_group_name" {
  default = "default.redis5.0"
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

variable "instance_type_app" {
  default = "t3.medium"
}

variable "instance_type_idp" {
  default = "t3.medium"
}

variable "instance_type_jumphost" {
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

variable "use_spot_instances" {
  description = "Use spot instances for roles suitable for spot use"
  type        = number
  default     = 0
}

variable "name" {
  default = "login"
}

variable "region" {
  default = "us-west-2"
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

# Auto scaling flags
variable "asg_auto_recycle_enabled" {
  default     = 0
  description = "Whether to automatically recycle IdP/app/outboundproxy servers every 6 hours"
}

variable "asg_recycle_business_hours" {
  default     = 0
  description = "If set to 1, recycle only once/day during business hours Mon-Fri, not every 6 houts"
}

# Auto scaling group desired counts
variable "asg_jumphost_desired" {
  default = 0
}

variable "asg_idp_min" {
  default = 0
}

variable "asg_idp_desired" {
  default = 0
}

variable "asg_idp_max" {
  default = 8
}

variable "asg_idpxtra_min" {
  default = 0
}

variable "asg_idpxtra_desired" {
  default = 0
}

variable "asg_idpxtra_max" {
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
  default = 0
}

variable "asg_pivcac_desired" {
  default = 2
}

variable "asg_pivcac_max" {
  default = 4
}

variable "asg_outboundproxy_desired" {
  default = 3
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

variable "idpxtra_client_ids" {
  description = "Map of friendly names (keys) to client ID/OIDC arns (values) to be routed to idpxtra pool"
  # Example: {"sba_dlap" = "urn:gov:gsa:openidconnect.profiles:sp:sso:sba:dlap"}
  type    = map(string)
  default = {}
}

variable "idpxtra_sp_networks" {
  # WARNING - ANY IP matching these lists will get routed to idpxtra, including
  #           users.  Use this feature only when really needed or for explicit testing!
  description = "Map of friendly names to lists of CIDR blocks to route to idpxtra pool, used for SP to IdP token and other requests"
  type        = map(list(string))
  # Example: {"sba_dlap" = ["5.5.5.0/24", "7.7.5.1/32"]}
  default = {}
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
  default     = "ami-0db336f366bcaa64d" # 2022-05-23 Ubuntu 18.04
  description = "default AMI ID for environments in the sandbox account"
}

variable "default_ami_id_prod" {
  default     = "ami-0cd15a15ccae71ca2" # 2022-05-23 Ubuntu 18.04
  description = "default AMI ID for environments in the prod account"
}

variable "rails_ami_id_sandbox" {
  default     = "ami-07cf6baf5d1b1de68" # 2022-05-23 Ubuntu 18.04
  description = "AMI ID for Rails (IdP/PIVCAC servers) in the sandbox account"
}

variable "rails_ami_id_prod" {
  default     = "ami-0a53cf38ab0110428" # 2022-05-23 Ubuntu 18.04
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

locals {
  bootstrap_main_s3_ssh_key_url    = var.bootstrap_main_s3_ssh_key_url != "" ? var.bootstrap_main_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? var.bootstrap_private_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default != "" ? var.bootstrap_main_git_ref_default : "stages/${var.env_name}"
  account_default_ami_id           = data.aws_caller_identity.current.account_id == "555546682965" ? var.default_ami_id_prod : var.default_ami_id_sandbox
  account_rails_ami_id             = data.aws_caller_identity.current.account_id == "555546682965" ? var.rails_ami_id_prod : var.rails_ami_id_sandbox
  high_priority_alarm_actions      = var.page_devops == 1 ? [var.high_priority_sns_hook, var.slack_events_sns_hook_arn] : [var.slack_events_sns_hook_arn]
  low_priority_alarm_actions       = [var.slack_events_sns_hook_arn]
  high_priority_alarm_actions_use1 = var.page_devops == 1 ? [var.high_priority_sns_hook_use1, var.slack_events_sns_hook_arn_use1] : [var.slack_events_sns_hook_arn_use1]
  low_priority_alarm_actions_use1  = [var.slack_events_sns_hook_arn_use1]
  inventory_bucket_arn             = "arn:aws:s3:::login-gov.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  dnssec_runbook_prefix            = " - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec"
}

# These variables are used to toggle whether certain services are enabled.
#
# NOTE: These must be numbers, as terraform does not support boolean values,
# only numbers and strings.
#
# See: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

variable "cloudfront_tlstest_enabled" {
  default     = 0
  description = "Enable the cloudfront endpoints for testing SNI and TLSv1.2 compatibility"
}

variable "alb_http_port_80_enabled" {
  default     = 1
  description = "Whether to have ALB listen on HTTP port 80 (not just HTTPS 443)"
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

variable "kms_log_kinesis_shards" {
  description = "Number of shards to provision in Kinesis datastream for kms logging"
  default     = 1
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

variable "sms_send_rate_alert_threshold" {
  description = "If more than this number of SMS deliveries is exeeded in a minute, we alert"
  default     = 100
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

variable "tf_slack_channel" {
  description = "Slack channel to send events to."
  default     = "#login-personal-events"
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

variable "performance_insights_enabled" {
  default     = "true"
  description = "Enables Performance Insights on RDS"
}

variable "enable_cloudwatch_slos" {
  type    = bool
  default = true
}

variable "low_memory_alert_enabled" {
  description = "set this to 1 if you want to alert on low memory alert in New Relic"
  default     = 0
}

variable "memory_free_threshold_byte" {
  description = "Low memory threshold in bytes for New Relic"
  default     = "524288000" #500 MB 
}

variable "unvacummed_transactions_count" {
  description = "The maximum transaction IDs(in count) that have been used by PostgreSQL."
  type        = string
  default     = "1000000000"
}

variable "ssm_session_timeout" {
  description = <<EOM
REQUIRED. Amount of time (in minutes) of inactivity to allow before an
SSM session ends. Defaults to 15 minutes.
EOM
  type        = number
  default     = 15
}
