variable "access_key" {}
variable "ami_id" {}
variable "app_sg_ssh_cidr_blocks" {}
variable "app_subnet_cidr_block" {}
variable "chef_ami_id" {}
variable "client" {}
variable "db1_subnet_cidr_block" {}
variable "db2_subnet_cidr_block" {}
variable "env_name" { default = "tf" }
variable "key_name" {}
variable "name" { default = "login" }
variable "region" { default = "us-west-2" }
variable "secret_key" {}
variable "vpc_cidr_block" {}
