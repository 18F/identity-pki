variable "cw_log_group" {
  type        = list(string)
  description = "Cloudwatch log group name for exporting logs to S3."
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket to store cloudwatch logs"
}