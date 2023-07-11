variable "name" {
  default = "login"
}

variable "env_name" {
}

variable "vpc_id" {
  description = "VPC Id to associate with the Route53 Private hosted zone"
}

variable "fisma_tag" {
  default = "Q-LG"
}