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
    "159.142.0.0/16",    # GSA VPN IPs
    "152.216.7.5/32",    # IRS - Public FCI Proxy - MTB for Prod
    "152.216.11.5/32",   # IRS - Public FCI Proxy - MEM for EITE and Prod
    "63.232.48.230/32",  # IRS - Public IEP Proxy - CO for PROD
    "67.134.209.230/32", # IRS - Public IEP Proxy - VA for EITE and PROD
  ]
}

variable "privileged_cidr_blocks_v6" {
  description = "List of additional IPv6 CIDR blocks that should be allowed access to restricted endpoints"
  type        = list(string)
  default = [
  ]
}

