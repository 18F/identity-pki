variable "domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov'"
  type        = string
}

variable "email_bucket" {
  description = "Bucket used to store inbound SES mail"
  type        = string
}
variable "email_bucket_prefix" {
  default     = "inbound/"
  description = "Prefix in the bucket to upload email under"
  type        = string
}

variable "rule_set_name" {
  default = "default-rule-set"
  type    = string
}

variable "email_users" {
  description = "List of additional users (besides admin) to accept - user@domain will be allowed and delivers to {var.email_bucket_prefix}user/"
  type        = list(string)
  default     = []
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

variable "usps_features_enabled" {
  default     = false
  description = "Generates resources necessary for usps status updates via email."
  type        = bool
}

variable "sandbox_features_enabled" {
  default     = false
  description = "Generates resources and features that should only be used in sandbox accounts"
  type        = bool
}
