variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "slack_notification_arn" {
  description = "ARN of the sns topic used in response plans"
  type        = string
}

variable "lambda_timeout" {
  type        = number
  default     = "900"
  description = "Timeout Value for Lambda"
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.12"
  description = "Runtime for Lambda"
}

variable "cloudwatch_retention_days" {
  default     = 0
  description = <<EOM
Number of days to retain CloudWatch Logs for all Log Groups defined in the module.
Defaults to 0 (never expire).
EOM
  type        = number
}
