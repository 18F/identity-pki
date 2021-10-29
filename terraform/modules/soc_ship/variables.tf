variable "region" {
  description = "AWS region identifier"
  default     = "us-west-2"
}

variable "cloudwatch_subscription_filter_name" {
  description = "The subscription filter name"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "The cloudwatch log group name"
  type        = list(any)
}

variable "cloudwatch_filter_pattern" {
  description = "The cloudwatch filter pattern"
  type        = string
}

variable "env_name" {
  description = "Environment Name"
  type        = string
}