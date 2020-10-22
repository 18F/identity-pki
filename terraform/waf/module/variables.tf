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

variable "waf_override" {
  description = "Values should be none for block or count for count"
  default = "count"
  type = string
}

variable "associate_alb" {
  description = "Associate alb with acl"
  type = bool
  default = true
}