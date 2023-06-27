variable "use_prefix" {
  type        = bool
  description = <<EOM
Whether or not to use a name_prefix (vs. a name) for resource naming.
EOM
  default     = true
}

variable "name" {
  default = "login"
}

variable "env_name" {
}

variable "vpc_cidr_block" { # 172.16.32.0   - 172.16.35.255
  default = "172.16.32.0/22"
}

variable "app_cidr_block" {
  type        = string
  description = "CIDR block for app-ACCOUNT defined in network_layout"
  default     = "100.106.0.0/16"
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
  description = "VPC Used To Launch the Outbound Proxy"
}

variable "github_ipv4_cidr_blocks" {
  type        = list(string)
  description = "List of GitHub's IPv4 CIDR ranges."
  default     = []
}
