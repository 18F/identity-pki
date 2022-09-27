variable "vpc_name" {}

variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "privileged_cidr_blocks_v4" {
  description = "List of additional IPv4 CIDR blocks that should be allowed access to restricted endpoints"
  type        = list(string)
  default = [
    "159.142.0.0/16", # GSA VPN IPs
  ]
}

variable "privileged_cidr_blocks_v6" {
  description = "List of additional IPv6 CIDR blocks that should be allowed access to restricted endpoints"
  type        = list(string)
  default = [
  ]
}

