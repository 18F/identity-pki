variable "env_name" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "name" {
  type        = string
  description = "Prefix string used in naming endpoint security groups"
  default     = "login"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "vpc_id" {
  type        = string
  description = "VPC for the environment"
}

variable "proxy_port" {
  type        = string
  description = "Port number to use with outboundproxy server"
  default     = "3128"
}

variable "obproxy_security_group" {
  type        = string
  description = "ID of the Security Group used with outboundproxy hosts"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR range used by VPC"
  default     = "172.16.32.0/22"
}

variable "s3_prefix_list_id" {
  type        = string
  description = "Prefix ID of private S3 endpoint created with VPC"
}

variable "aws_services" {
  type        = map(any)
  description = <<EOM
AWS services to create VPC endpoints/access for. Map defines whether or not
to create an egress rule for all ports to var.vpc_cidr_block
EOM
  default     = {}
}

variable "app_subnets" {
  type        = any
  description = <<EOM
Set of aws_subnet resources used with VPC endpoints/security groups.
aws_subnet.cidr_block and aws_subnet.id attributes used for defining said rules.
EOM
}
