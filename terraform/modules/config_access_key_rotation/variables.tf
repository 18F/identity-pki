variable "config_access_key_rotation_name" {
  type = string
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "config_access_key_rotation_accounts" {
  type        = list(string)
  description = "Enter the account ID's for the iam policy principal."
}

variable "config_access_key_rotation_frequency" {
  type        = string
  description = "The frequency that you want AWS Config to run evaluations for the rule."
  default     = "One_Hour"
}

variable "config_access_key_rotation_max_key_age" {
  type        = string
  description = "Maximum number of days without rotation. Default 90."
  default     = 90
}

variable "config_access_key_rotation_code" {
  type        = string
  description = "Enter the path of the compressed lambda source code. e.g: (../keys/src/config-access-key-rotation.zip)"
}