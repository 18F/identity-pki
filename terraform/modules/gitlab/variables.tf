variable "gitlab_servicename" {
  description = "the service_name of the gitlab privatelink service"
}

variable "vpc_id" {
  description = "the VPC where this endpoint lives"
}

variable "allowed_security_groups" {
  description = "security groups allowed into this privatelink endpoint"
}

variable "route53_zone_id" {
  description = "the zone id that you want to write the dns_name into"
}

variable "dns_name" {
  description = "dns name for the privatelink endpoint"
}

variable "name" {
  description = "prefix to use for the vpc endpoint"
  default     = "login"
}

variable "env_name" {}

variable "endpoint_subnet_ids" {
  description = "list of subnet_ids to house the privatelink endpoint"
  default     = "login"
}
