variable "config_access_key_rotation_name" {
  description = "Name of the Config access key rotation, used to name other resources"
  type        = string
  default     = "cfg-access-key-rotation"
}

variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "config_access_key_rotation_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/config-access-key-rotation.zip"
}

variable "lambda_timeout" {
  type        = number
  default     = "900"
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