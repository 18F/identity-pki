locals {
  bootstrap_main_s3_ssh_key_url    = var.bootstrap_main_s3_ssh_key_url != "" ? var.bootstrap_main_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? var.bootstrap_private_s3_ssh_key_url : "s3://login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default != "" ? var.bootstrap_main_git_ref_default : "stages/${var.env_name}"
  account_default_ami_id           = var.default_ami_id_tooling
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

variable "allowed_gitlab_cidr_blocks_v4" { # 159.142.0.0 - 159.142.255.255
  default = [
    "159.142.0.0/16",
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

variable "asg_outboundproxy_desired" {
  default = 3
}

variable "asg_outboundproxy_min" {
  default = 1
}

variable "asg_outboundproxy_max" {
  default = 9
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
  default     = "ami-037fbabb417fa077e" # 2021-08-09 Ubuntu 18.04
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

variable "instance_type_outboundproxy" {
  default = "t3.medium"
}

variable "name" {
  default = "login"
}

variable "region" {
  default = "us-west-2"
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
  default = "44.230.151.136/32"
}

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
    gitlab        = 1
  }
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
  default = "gitlab.identitysandbox.gov"
}

variable "route53_id" {
  default = "Z096400532ZFM348WWIAA"
}

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
