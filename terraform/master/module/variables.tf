variable "region" {
  default = "us-west-2"
}

variable "master_account_id" {
  default = "340731855345"
}

variable "prod_aws_account_nums" {
  description = "List of account numbers for 'Prod'-type AWS accounts."
  default     = [
    "555546682965", # login-prod
    "472911866628", # login-sms-prod
    "461353137281", # login-analytics-prod
    "217680906704", # login-secops-prod
  ]
}

variable "nonprod_aws_account_nums" {
  description = "List of account numbers for 'NonProd'-type (Sandbox, Dev, etc.) AWS accounts."
  default     = [
    "894947205914", # login-sandbox
    "035466892286", # login-sms-sandbox
    "138431511372", # login-secops-dev
    "034795980528", # login-interviews
  ]
}

variable "role_list" {
  description = "List of roles available in the various AWS accounts."
  default     = [
    "FullAdministrator",
    "PowerUser",
    "ReadOnly",
    "BillingReadOnly",
    "ReportsReadOnly",
    "KMSAdministrator",
    "SOCAdministrator",
  ]
}

variable "auditor_accounts" {
  description = "Map of non-Login.gov AWS accounts we allow Security Auditor access to"
  # Unlike our master account, these are accounts we do not control!
  type        = map(string)
  default     = {
    master        = "340731855345" # Include master for testing
    techportfolio = "133032889584" # TTS Tech Portfolio
  }
}
