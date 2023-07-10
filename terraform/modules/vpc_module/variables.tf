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

variable "vpc_cidr_block" {
  description = "Primary CIDR for the new vpc"
}

variable "secondary_cidr_block" {
  description = "Secondary cidr block for the vpc from network_layout module"
}

variable "az" {
  description = "Availability Zones in the provided region from network_layout module"
}

variable "flow_log_iam_role_arn" {
  description = "IAM role arn for pushing vpc flow logs to cloudwatch"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "enable_data_services" {
  description = "Condition to build subnets using CIDR range from network_layout module for data_services"
  type        = bool
}

variable "enable_app" {
  description = "Condition to build subnets using CIDR range from network_layout module for app"
  type        = bool
}

variable "rds_db_port" {
  type        = number
  description = "Database port number"
  default     = 5432
}

variable "nessusserver_ip" {
  description = "Nessus server's public IP"
}

variable "nessus_public_access_mode" {
}

variable "additional_sg_id" {
  default = ""
}

variable "outbound_subnets" {
  #default = ["0.0.0.0/0"]
  #default = ["127.0.0.1/32"] # use localhost as hack since TF doesn't handle empty list well
  default = ["172.17.32.0/22"]
  type    = list(string)
}

variable "github_ipv4_cidr_blocks" {
  type        = list(string)
  description = "List of GitHub's IPv4 CIDR ranges."
  default     = []
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