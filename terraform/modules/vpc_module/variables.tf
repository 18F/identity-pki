variable "region" {
  description = "AWS Region"
}

variable "name" {
  default = "login"
}

variable "env_name" {
}

variable "env_type" {
}

variable "vpc_cidr_block" { # 172.17.32.0 - 172.17.35.255
  description = "Primary CIDR for the new vpc"
}

variable "secondary_cidr_block" {
  description = "Secondary cidr block for the vpc from network_layout module"
}

variable "az" {
  description = "Availability Zones in the provided region from network_layout module"
}

variable "vpc_ssm_parameter_prefix" {
  description = "SSM parameter prefix for vpc id"
}

variable "flow_log_iam_role_arn" {
  description = "IAM role arn for pushing vpc flow logs to cloudwatch"
}

variable "enable_data_services" {
  description = "Purpose type for the subnets to be built using CIDR range from network_layout module"
  type        = bool
}

variable "enable_app" {
  description = "Purpose type for the subnets to be built using CIDR range from network_layout module"
  type        = bool
}

variable "db_inbound_acl_rules" {
  description = "DB subnets inbound network ACLs"
  type        = list(map(string))
  default     = []
}

variable "db_outbound_acl_rules" {
  description = "DB subnets outbound network ACLs"
  type        = list(map(string))
  default     = []
}

variable "db_security_group_ingress" {
  description = "List of maps of ingress rules to set on the security group"
  type        = list(map(string))
  default     = []
}

variable "db_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

variable "app_inbound_acl_rules" {
  description = "App subnets inbound network ACLs"
  type        = list(map(string))
  default     = []
}

variable "app_outbound_acl_rules" {
  description = "App subnets outbound network ACLs"
  type        = list(map(string))
  default     = []
}

variable "app_security_group_ingress" {
  description = "List of maps of ingress rules to set on the security group"
  type        = list(map(string))
  default     = []
}

variable "app_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}