variable "region" {
  type        = string
  description = "AWS Region"
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

variable "schedule" {
  type        = string
  description = "Cron expression for cloudwatch event rule schedule"
  default     = "cron(0 22 * * ? *)"
}