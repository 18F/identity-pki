data "aws_caller_identity" "current" {}

variable "env_name" {
  description = "Environment Name"
  type        = string
}

variable "region" {
  description = "AWS region identifier"
  type        = string
  default     = "us-west-2"
}

variable "apps_enabled" {
}

