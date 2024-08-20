variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name" {
  type    = string
  default = "login"
}

variable "account_name" {
  type        = string
  description = "The login.gov alias associated with the account. Primarily used for identifying resources."
}

variable "fisma_tag" {
  type    = string
  default = "Q-LG"
}

variable "image_build_nat_eip" {
  description = <<EOM
Elastic IP address for the NAT gateway.
Must already be allocated via other means.
EOM
  type        = string
}

variable "image_build_private_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
  default     = "10.0.11.0/24"
}

variable "image_build_public_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "image_build_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/19"
}

variable "assign_generated_ipv6_cidr_block" {
  description = "enable ipv6"
  type        = bool
  default     = "false"
}

variable "cloudwatch_retention_days" {
  description = "Cloudwatch Retention Policy"
  type        = number
  default     = 90
}
