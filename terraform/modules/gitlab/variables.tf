variable "gitlab_servicename" {
	description = "the service_name of the gitlab privatelink service"
}

variable "gitlab_subnet_cidr_block" {
	description = "the netblock we split up for use by the privatelink endpoint"
}

variable "vpc_id" {
	description = "the VPC where this endpoint lives"
}

variable "allowed_security_groups" {
  description = "security groups allowed into this privatelink endpoint"
}

variable "name" {}

variable "env_name" {}
