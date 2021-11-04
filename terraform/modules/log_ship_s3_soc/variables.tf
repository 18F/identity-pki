variable "region" {
  description = "AWS region identifier"
  default     = "us-west-2"
}
variable "cloudwatch_subscription_filter_name" {
  description = "The subscription filter name"
  type        = string
}

variable "env_name" {
  description = "Environment Name"
  type        = string
}

variable "soc_destination_arn" {
  description = "string"
  type        = string
}
variable "cloudwatch_log_group_name" {
  type = map(string)
}
