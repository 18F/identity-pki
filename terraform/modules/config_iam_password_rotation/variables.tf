variable "region" {
  type        = string
  description = "AWS Region"
}

variable "password_rotation_frequency" {
  type        = string
  description = "The frequency that you want AWS Config to run evaluations for the rule."
}

variable "config_password_rotation_name" {
  description = "Name of the Config password rotation, used to name other resources"
  type        = string
  default     = "cfg-password-rotation"
}

variable "config_password_rotation_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "lambda/config-password-rotation.zip"
}

variable "password_rotation_max_key_age" {
  type        = string
  description = "Maximum number of days without rotation."
  default     = 90
}

variable "slack_events_sns_topic" {
  type        = string
  description = "Name of the SNS topic for pushing notification from lambda."
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
