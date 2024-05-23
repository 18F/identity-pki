variable "domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov'"
  type        = string
}

variable "rule_set_name" {
  default     = "default-rule-set"
  description = "The SES rule set to add receipt rules"
  type        = string
}

variable "usps_envs" {
  default     = []
  description = "List of internal environments to allow receiving email messages"
  type        = list(string)
}

variable "usps_ip_addresses" {
  type        = list(string)
  description = "List of permitted USPS IP address blocks to allow receiving email messages"
  default = [
    "56.0.84.0/24",
    "56.0.86.0/24",
    "56.0.103.0/24",
    "56.0.143.0/24",
    "56.0.146.0/24",
  ]
}
