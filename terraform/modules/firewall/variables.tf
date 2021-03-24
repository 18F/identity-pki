variable "az_zones" {
  description = "The list of availability zones"
  type = list(string)
  }

variable "firewall_cidr_blocks" {
  description = "Firewall subnet CIDR blocks"
 type = map(string)
}

variable "eip_allocation_blocks" {
  description = "EIP NAT Gateway Allocation blocks"
  type = map(string)
}

variable "nat_cidr_blocks" {
  description = "NAT subnet CIDR blocks"
  type = map(string)
}

variable "firewall_cidr_block_aza" {
  description = "Firewall subnet CIDR block az-a"
  type = string
}

variable "nat_cidr_block_aza" {
  description = "NAT subnet CIDR block az-a"
  type = string
}

variable "firewall_cidr_block_azb" {
  description = "Firewall subnet CIDR block az-b"
  type = string
}

variable "nat_cidr_block_azb" {
  description = "NAT Subnet CIDR block az-b"
  type = string
}
variable "target_types" {
  description = "The protocols that will be inspected, TLS_SNI for HTTPS and HTTP_HOST for HTTP."
  type = list(string)
}

variable "rules_type" {
  description = "Specify whether domains in the target list are allowed or denied access. Valid values: ALLOWLIST, DENYLIST"
  type = string
}

variable "env_name" {
  type = string
}

variable "slack_events_sns_hook_arn"{
  type = string
}

variable "vpc_id" {
type = string
}

variable "name" {
  type = string
}

variable "nat_subnet_id_usw2a" {
  type = string
}

variable "nat_subnet_id_usw2b" {
  type = string
}

variable "gateway_id" {
  type = string
}
