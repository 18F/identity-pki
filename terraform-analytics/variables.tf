variable "env_name" {}
variable "redshift_master_password" {}
variable "vpc_cidr_block" { default = "10.1.0.0/16" }
variable "analytics_version" {}
variable "region" { default = "us-west-2"}
variable "version_info_bucket" { default = "login-dot-gov-analytics-terraform-state" }
variable "version_info_region" { default = "us-west-2" }
