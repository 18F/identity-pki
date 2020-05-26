variable "region" {
  description = "AWS Region where this account lives."
}

variable "master_account_id" {
  description = "AWS Account ID for the master account."
}

variable "prod_aws_account_nums" {
  description = "List of account numbers for 'Prod'-type AWS accounts."
  default     = []
}

variable "nonprod_aws_account_nums" {
  description = "List of account numbers for 'NonProd'-type (Sandbox, Dev, etc.) AWS accounts."
  default     = []
}

variable "role_list" {
  description = "List of roles available in the various AWS accounts."
  default     = []
}

variable "auditor_accounts" {
  description = "Map of non-Login.gov AWS accounts we allow Security Auditor access to"
  # Unlike our master account, these are accounts we do not control!
  type        = map(string)
  default     = {}
}
