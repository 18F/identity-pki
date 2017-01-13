variable "app_sg_ssh_cidr_blocks" {type="list"}
variable "vpc_cidr_block"         { default = "172.16.0.0/16" }
variable "db1_subnet_cidr_block"  { default = "172.16.0.0/28" }
variable "db2_subnet_cidr_block"  { default = "172.16.0.16/28"}
variable "chef_subnet_cidr_block" { default = "172.16.0.32/28"}
variable "app_subnet_cidr_block"  { default = "172.16.1.0/24" }
variable "jumphost_subnet_cidr_block" { default = "172.16.0.48/28"}
variable "env_name" { default = "tf" }
variable "key_name" {}
variable "name" { default = "login" }
variable "region" { default = "us-west-2" }
variable "ami_id" {}
variable "default_ami_id" {}
variable "client" {}

variable "chef_version" { default = "12.15.19" }
variable "chef_url" { default = "https://chef.login.gov.internal/organizations/login-dev" }
variable "chef_databag_key_path" {}
variable "chef_id" {}
variable "chef_info" {}
variable "chef_id_key_path" {}
variable "chef_repo_gitref" { default = "master" }
variable "live_certs" {}

variable "git_deploy_key_path" {}

