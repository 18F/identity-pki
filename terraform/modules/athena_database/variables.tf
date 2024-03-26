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

variable "queries" {
  type = list(object({
    name  = string
    query = string
  }))
  default     = []
  description = "List of queries to be saved in the athena."
}
