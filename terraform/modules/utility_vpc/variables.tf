variable "region" {
  default = "us-west-2"
}

variable "name" {
  default = "login"
}

variable "account_name" {
}

variable "fisma_tag" {
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

variable "associate_public_ip" {
  description = "associate a public IP"
  type        = bool
  default     = "false"
}

variable "assign_generated_ipv6_cidr_block" {
  description = "enable ipv6"
  type        = bool
  default     = "false"
}