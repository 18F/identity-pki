variable "billing_email_list" {
  description = "List of email addresses to send billing email to"
  type        = list(string)
  default = [
    "identity-devops@login.gov",
  ]
}

variable "budget_monthly_all" {
  description = "Monthly budget accross all accounts"
  type        = number
  default     = 350000
}

