variable "name" {
  default = "login"
}

variable "env_name" {
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "vpc_cidr_block" { # 172.16.32.0   - 172.16.35.255
  default = "172.16.32.0/22"
}

variable "vpc_secondary_cidr_block" {
  type        = string
  description = "Secondary CIDR block for the vpc assigned from network_layout"
}

variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
  default     = "44.230.151.136/32"
}

variable "s3_prefix_list_id" {
}

variable "vpc_id" {
  description = "VPC Used To Launch the Migration Host"
}

variable "github_ipv4_cidr_blocks" {
  type        = list(string)
  description = "List of GitHub's IPv4 CIDR ranges."
  default     = []
}

variable "migration_subnet_ids" {
  type        = list(string)
  description = "List of subnets to use for the migration host ASG"
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

variable "asg_enabled_metrics" {
  type        = list(string)
  description = "A list of cloudwatch metrics to collect on ASGs https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#enabled_metrics"
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
  Name of one of the blocks defined in var.migration_rotation_schedules, which defines
  the cron schedules for recycling and/or 'autozero' scheduled actions.
  MUST match one of the key names in var.migration_rotation_schedules.
  EOM
  type        = string
  default     = "nozero_norecycle"
}

variable "migration_rotation_schedules" {
  description = <<EOM
Customized set of cron jobs for recycling (up/down) and/or zeroing out hosts.
MUST follow the defined format as shown for the default value!
EOM
  type        = any
  default = {
    #   "custom_schedule" = {
    #     recycle_up    = ["0 11 * * 1-5"]
    #     recycle_down  = ["15 11 * * 1-5"]
    #     autozero_up   = ["0 5 * * 1-5"]
    #     autozero_down = ["0 17 * * 1-5"]
    #   }
  }
}

variable "ami_id_map" {
  type        = map(string)
  description = "Mapping from server role to an AMI ID, overrides the default_ami_id if key present"
  default     = {}
}

variable "default_ami_id" {
  description = "default AMI ID for environments in the account"
}

variable "instance_type_migration" {
  default = "t3.medium"
}

variable "migration_instance_profile" {
}

variable "base_security_group_id" {
  type        = string
  description = "security group used on client side for outbound proxy"
}

variable "bootstrap_private_git_clone_url" {
  default     = "git@github.com:18F/identity-devops-private"
  description = "URL for provision.sh to use to clone identity-devops-private"
}

variable "bootstrap_private_git_ref" {
  default     = "main"
  description = "Git ref in identity-devops-private for provision.sh to check out."
}

variable "bootstrap_private_s3_ssh_key_url" {
  default     = ""
  description = "S3 path to find an SSH key for cloning identity-devops-private, overrides the default value in locals if set."
}

variable "bootstrap_main_git_clone_url" {
  default     = "git@github.com:18F/identity-devops"
  description = "URL for provision.sh to use to clone identity-devops"
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

# proxy settings
variable "proxy_server" {
}

variable "proxy_port" {
}

variable "no_proxy_hosts" {
}

variable "proxy_enabled_roles" {
  type        = map(string)
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
}

variable "rails_ami_id_sandbox" {
  default     = "ami-052fb3ebc6de54174" # 2023-06-20 Ubuntu 20.04
  description = "AMI ID for Rails (IdP/PIVCAC servers) in the sandbox account"
}

variable "rails_ami_id_prod" {
  default     = "ami-014821bb837d6a777" # 2023-06-20 Ubuntu 20.04
  description = "AMI ID for Rails (IdP/PIVCAC servers) in the prod account"
}

variable "slack_events_sns_hook_arn_use1" {
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack from US-East-1"
  default     = ""
}