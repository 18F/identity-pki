variable "ami_deleted_days" {
  description = "Number of days before deleting an AMI"
  type        = string
  default     = "30"
}

variable "ami_deprecated_days" {
  description = "Number of days before deprecating an AMI"
  type        = string
  default     = "7"
}