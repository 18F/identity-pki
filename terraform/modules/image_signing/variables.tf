variable "additional_policy_statements" {
  default     = []
  type        = list(any)
  description = "Additional policy statements on top of full admin access"
}
