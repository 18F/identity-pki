variable "az_zones" {
  description = "The list of availability zones"
  default = ["us-west-2a", "us-west-2b"]
}

variable "firewall_cidr_blocks" {
  description = "Firewall subnet CIDR blocks"
  default = {
   us-west-2a = "172.16.34.0/28"
   us-west-2b = "172.16.34.16/28"
  }
}

variable "eip_allocation_blocks" {
  description = "EIP NAT Gateway Allocation blocks"
  default = {
   us-west-2a = "eipalloc-22fcd71f"
   us-west-2b = "eipalloc-3afad107"
  }
}

variable "nat_cidr_blocks" {
  description = "NAT subnet CIDR blocks"
  default = {
   us-west-2a = "172.16.34.64/28"
   us-west-2b = "172.16.34.80/28"
  }
}

variable "firewall_cidr_block_aza" {
  description = "Firewall subnet CIDR block az-a"
  default = "172.16.34.0/28"
}

variable "nat_cidr_block_aza" {
  description = "NAT subnet CIDR block az-a"
  default = "172.16.34.64/28"
}

variable "firewall_cidr_block_azb" {
  description = "Firewall subnet CIDR block az-b"
  default = "172.16.34.16/28"
}

variable "nat_cidr_block_azb" {
  description = "NAT Subnet CIDR block az-b"
  default = "172.16.34.80/28"
}

variable "target_types" {
  description = "The protocols that will be inspected, TLS_SNI for HTTPS and HTTP_HOST for HTTP."
  default = ["HTTP_HOST","TLS_SNI"]
}

variable "rules_type" {
  description = "Specify whether domains in the target list are allowed or denied access. Valid values: ALLOWLIST, DENYLIST"
  default = "ALLOWLIST"
}
