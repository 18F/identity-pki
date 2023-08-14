variable "ami_deleted_days" {
  description = "Number of days before deleting AMIs"
  type        = string
  default     = "30"
}

variable "ami_deprecated_days" {
  description = "Number of days before deprecating AMIs"
  type        = string
  default     = "7"
}