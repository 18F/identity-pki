variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "lambda_timeout" {
  type        = number
  default     = "180"
  description = "Timeout Value for Lambda"
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime for Lambda"
}

variable "ses_events_lambda" {
  type        = string
  description = "Lambda evaluating SES events captured by the configuration sets"
  default     = "SESAllEvents_Lambda"
}

variable "ses_events_queue" {
  type        = string
  description = "Sqs queue capturing the SES events via SNS"
  default     = "all_events_queue"
}

variable "ses_events_dlq" {
  type        = string
  description = "Sqs dead letter queue capturing the SES events via SNS"
  default     = "all_events_dead_letter_queue"
}

variable "ses_verified_identity" {
  type        = string
  description = "SES Verified Domain/Email Address"
  default     = "identitysandbox.gov"
}