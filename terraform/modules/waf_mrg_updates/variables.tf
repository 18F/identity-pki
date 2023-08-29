variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "aws_managed_sns_topic" {
  description = "AWS Managed SNS topic"
  type        = string
  default     = "arn:aws:sns:us-east-1:248400274283:aws-managed-waf-rule-notifications"
}

variable "lambda_timeout" {
  type        = number
  default     = "300"
  description = "Timeout Value for Lambda"
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime for Lambda"
}

variable "lambda_memory_size" {
  type        = string
  default     = "3008"
  description = "Memory Size"
}

variable "prefix" {
  type    = string
  default = "waf-mrg-version-updates"
}

variable "sns_to_slack" {
  description = "ARN of SNS topic to send notification"
}