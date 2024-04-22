variable "region" {
  description = "AWS Region where this account lives."
}

variable "fisma_tag" {
  default = "Q-LG"
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
  type        = map(map(list(string)))
}

variable "group_role_map" {
  description = "Roles map for IAM groups, along with account types per role to grant access to."
  type        = map(list(map(list(string))))
}

variable "default_email_domain" {
  description = <<EOM
If a user does not have an explicit email address in the user_map,
then their email is set to this domain: (their username)@(default_email_domain)
EOM
  type        = string
}
