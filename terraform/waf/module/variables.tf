locals {
  name_prefix = "${var.env}-idp-waf"
}

data "aws_caller_identity" "current" {}

variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "env" {
  description = "Environment name"
}

variable "enforce" {
  description = "Set to true to enforce WAF rules or false to just count traffic matching rules"
  type        = bool
  default     = false
}

variable "associate_alb" {
  description = "Associate alb with acl"
  type        = bool
  default     = true
}