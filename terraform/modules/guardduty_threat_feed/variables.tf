variable "guardduty_threat_feed_name" {
  description = "Name of the GuardDuty threat feed, used to name other resources"
  type        = string
  default     = "gd-threat-feed"
}

variable "region" {
  default = "us-west-2"
}

variable "guardduty_days_requested" {
  type    = number
  default = 7
}

variable "guardduty_frequency" {
  type    = number
  default = 6
}

variable "guardduty_threat_feed_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/guard-duty-threat-feed.zip"
}

variable "logs_bucket" {
  description = "Name of the bucket to store access logs in"
}

variable "inventory_bucket_arn" {
  description = "ARN of the bucket used for S3 Inventory"
}
