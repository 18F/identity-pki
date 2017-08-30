variable "env_name" {}
variable "redshift_master_password" {}
variable "vpc_cidr_block" { default = "10.1.0.0/16" }
variable "analytics_version" {}
variable "region" { default = "us-west-2"}
variable "kms_key_id" { default = "dc12706b-50ea-40b7-8d0e-206962aaa8f7" }
variable "num_redshift_nodes" { default = 3 }
variable "version_info_bucket" { default = "login-dot-gov-analytics-terraform-state" }
variable "version_info_region" { default = "us-west-2" }
