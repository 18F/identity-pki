variable "access_key" {}
variable "account_id" {}
variable "ami_id" {}
variable "app_sg_ssh_cidr_blocks" {}
variable "app_subnet_cidr_block" {}
variable "chef_ami_id" {}
variable "client" {}
variable "env_name" { default = "dev" }
variable "key_name" {}
variable "name" { default = "login-sandbox" }
variable "region" { default = "us-west-2" }
variable "secret_key" {}
variable "subnet_cidr_block_chef" { default = "172.16.11.0/28" }
variable "vpc_cidr_block_chef" { default = "172.16.33.0/27" }
