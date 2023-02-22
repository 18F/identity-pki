variable "env" {
  description = "Environment (prod/int/dev)"
}

variable "role" {
  description = "Host role (idp/jumphost/etc)"
}

variable "domain" {
  description = "Second level domain, e.g. login.gov"
}

variable "chef_download_url" {
  description = "URL to download chef debian package. If set to empty string, skip chef download."
  default     = ""
}

variable "chef_download_sha256" {
  description = "Expected SHA256 checksum of chef debian package"
  default     = ""
}

variable "private_s3_ssh_key_url" {
  description = "S3 URL to use to download SSH key used to clone the private_git_clone_url"
}

variable "private_git_clone_url" {
  description = "Git SSH URL used to clone identity-devops-private"
}

variable "private_git_ref" {
  description = "Git ref to check out after cloning private_git_clone_url"
  default     = "HEAD"
}

variable "private_lifecycle_hook_name" {
  description = "Name of the ASG lifecycle hook to notify upon private provision.sh completion"
  default     = "provision-private"
}

variable "main_s3_ssh_key_url" {
  description = "S3 URL to use to download SSH key used to clone the main_git_clone_url"
}

variable "main_git_clone_url" {
  description = "Git SSH URL used to clone identity-devops"
}

variable "main_git_ref_map" {
  description = "Mapping from role to the git ref to check out after cloning main_git_clone_url"
  type        = map(string)
  default     = {}
}

variable "main_git_ref_default" {
  description = "Default git ref to check out after cloning main_git_clone_url if no value set for role in main_git_ref_map"
  default     = "HEAD"
}

variable "proxy_server" {
  description = "URL to outbound proxy server"
}

variable "proxy_port" {
  description = "Port for outbound proxy server"
}

variable "no_proxy_hosts" {
  description = "Comma delimited list of hostnames, ip's and domains that should not use outbound proxy"
}

variable "proxy_enabled_roles" {
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  type        = map(number)
}

variable "main_lifecycle_hook_name" {
  description = "Name of the ASG lifecycle hook to notify upon main provision.sh completion"
  default     = "provision-main"
}

variable "override_asg_name" {
  description = "Auto scaling group name. If not set, defaults to $env-$role"
  default     = ""
}

variable "sns_topic_arn" {
  description = "ARN to send alerts alerts to, ultimately triggering Slack or other message"
  default     = ""
}

variable "s3_secrets_bucket_name" {
  description = "Name of bucket used to track user_data"
  default     = ""
}