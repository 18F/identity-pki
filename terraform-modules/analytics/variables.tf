variable "env_name" {}

variable "jumphost_cidr_block" {
  type = "map"

  default = {
    dev     = "34.216.215.128/26"
    qa      = "34.216.215.128/26"
    int     = "34.216.215.128/26"
    dm      = "34.216.215.0/26"
    staging = "34.216.215.0/26"
    prod    = "34.216.215.64/26"
    pt      = "34.216.215.128/26"
  }
}

variable "redshift_master_password" {}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "analytics_version" {}

variable "region" {
  default = "us-west-2"
}

variable "kms_key_id" {
  default = "5d2d42ec-6b7f-4705-a1bb-7f4021a0df4d"
}

variable "num_redshift_nodes" {
  default = 4
}

variable "name" {
  default = "login"
}

variable "wlm_json_configuration" {
  default = "[{\"query_concurrency\": 50}]"
}
