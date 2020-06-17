variable "lambda_name" {
  description = "Lambda name"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout for lambda function"
  default     = 90
}

variable "lambda_memory" {
  description = "Memory allocated to lambda function, 128MB to 3,008MB in 64MB increments"
  default     = 128
}

variable "lambda_package" {
  description = "Lambda source package file location"
}

variable "lambda_description" {
  description = "Lambda description"
}

variable "kms_key_arn" {
  description = "KMS key id"
}

variable "s3_bucket_arn" {
  description = "S3 bucket arn"
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
}

variable "ssm_parameter_name" {
  description = "SSM parameter name for lambda function"
}
