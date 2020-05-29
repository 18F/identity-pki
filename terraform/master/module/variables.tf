variable "region" {
  description = "AWS Region where this account lives."
}

variable "aws_account_types" {
  description = "AWS accounts grouped by type"
  type        = map(list(string))
  # Example value: {"Prod" = [123, 543, 125], "Dev" = [454, 232]}
}

variable "master_account_id" {
  description = "AWS Account ID for the master account."
}

variable "role_list" {
  description = "List of roles available in the various AWS accounts."
  default     = []
}

variable "user_map" {
  description = "Map of users to group memberships."
  type        = map(list(string))
}

variable "group_role_map" {
  description = "Roles map for IAM groups, along with account types per role to grant access to."
  type = map(list(map(list(string))))
}

variable "auditor_accounts" {
  description = "Map of non-Login.gov AWS accounts we allow Security Auditor access to"
  # Unlike our master account, these are accounts we do not control!
  type        = map(string)
  default     = {}
}
