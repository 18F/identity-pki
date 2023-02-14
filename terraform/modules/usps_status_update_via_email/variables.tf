variable "env_name" {
  type        = string
  description = "The environment name. Inherited from module declaration"
}

variable "root_domain" {
  type        = string
  description = "The root domain of the environment. Inherited from module declaration"
}

variable "route53_id" {
  type        = string
  description = "The route53 parent zone id. Inherited from module declaration"
}
