variable "env_name" {}
variable "jumphost_cidr_block" {
  type = "map"
  default = {
    dev = "52.33.21.52/32"
    qa = "34.208.151.117/32"
    int = "52.38.156.57/32"
    dm = "52.37.18.62/32"
    staging = "52.26.32.80/32"
    prod = "34.208.176.143/32"
  }
}
variable "redshift_master_password" {}
variable "vpc_cidr_block" { default = "10.1.0.0/16" }
variable "analytics_version" {}
variable "region" { default = "us-west-2"}
variable "kms_key_id" { default = "dc12706b-50ea-40b7-8d0e-206962aaa8f7" }
variable "num_redshift_nodes" { default = 3 }
variable "version_info_bucket" { default = "login-dot-gov-analytics-terraform-state" }
variable "version_info_region" { default = "us-west-2" }
variable "name" { default = "login" }
