variable "expire_associated_in_days" {
  description = "Number of days to expire an AMI that has been used."
  type        = string
  default     = "30"
}


variable "expire_unassociated_in_days" {
  description = "Number of days to expire an AMI that has not been used"
  type        = string
  default     = "7"
}
