variable "name" {
  default     = "login"
  description = "Inherited from app declaration"
}

variable "env_name" {
  description = "Inherited from app declaration"
}

variable "vpc_id" {

}

variable "cluster_name" {}

variable "clusters" {}

variable "public_subnet_ids" {}

variable "data_subnet_ids" {}
