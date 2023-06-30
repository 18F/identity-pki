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