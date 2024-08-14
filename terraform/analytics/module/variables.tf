variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "root_domain" {
  type        = string
  description = "DNS domain to use as the root domain, e.g. login.gov"
}
