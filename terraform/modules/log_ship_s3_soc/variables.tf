variable "region" {
  description = "AWS region identifier"
  default     = "us-west-2"
}

variable "kinesis_firehose_stream_name" {
  description = "Name to be use on kinesis firehose stream"
  type        = string
}

variable "kinesis_firehose_stream_backup_prefix" {
  description = "The prefix name to use for the kinesis backup"
  type        = string
  default     = "backup/"
}

variable "bucket_name" {
  description = "The bucket name"
  type        = string
}

variable "cloudwatch_subscription_filter_name" {
  description = "The subscription filter name"
  type        = string
}

variable "expiration_days" {
  description = "Expiration Days for S3 bucket"
  default     = "90"
  type        = string

}

variable "bucket_name_prefix" {
  description = "Bucket name prefix"
  default     = "login.gov"
  type        = string
}

variable "env_name" {
  description = "Environment Name"
  type        = string
}

variable "soc_destination_arn" {
  description = "string"
  type        = string
}

variable "cloudwatch_log_group_name" {
  type = map(string)
}

variable "send_logs_to_s3" {
  type = string
}