variable "region" {
}

variable "sandbox_account_id" {
  description = "Sandbox AWS Account ID"
}

variable "production_account_id" {
  description = "Production AWS Account ID"
}

variable "sandbox_sms_account_id" {
  description = "Sandbox Pinpoint AWS Account ID"
}

variable "production_sms_account_id" {
  description = "Production Pinpoint AWS Account ID"
}

variable "production_analytics_account_id" {
  default     = ""
  description = "Production Analytics AWS Account ID"
}

variable "sandbox_analytics_account_id" {
  default     = ""
  description = "Sandbox Analytics AWS Account ID"
}

variable "auditor_accounts" {
  description = "Map of non-Login.gov AWS accounts we allow Security Auditor access to"
  # Unlike our master account, these are accounts we do not control!
  type = map(string)
  default = {
    master        = "340731855345" # Include master for testing
    techportfolio = "133032889584" # TTS Tech Portfolio
  }
}
