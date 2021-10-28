variable "domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov'"
}

variable "email_bucket" {
  description = "Bucket used to store inbound SES mail"
}
variable "email_bucket_prefix" {
  description = "Prefix in the bucket to upload email under"
  default     = "inbound/"
}

variable "rule_set_name" {
  default = "default-rule-set"
}

variable "enabled" {
  description = "Hack for module-wide count, which TF doesn't support"
  default     = 0
}

variable "email_users" {
  # ONLY SET THIS IF "enabled" is 1!
  description = "List of additional users (besides admin) to accept - user@domain will be allowed and delivers to {var.email_bucket_prefix}user/"
  type        = list(string)
  default     = []
}
