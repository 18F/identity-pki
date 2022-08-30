variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS Region"
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

variable "ses_verified_identity" {
  type        = string
  description = "SES Verified Domain/Email Address"
}
