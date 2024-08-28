variable "cloudwatch_log_group_min_retention" {
  type        = number
  description = "Defines the minimum cloudwatch log group retention period AWS Config checks for"
  default     = 30
  validation {

    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_group_min_retention)
    error_message = <<-EOM
    AWS Config only supports a limited number of values for MinRetentionTime.
    Please review: https://docs.aws.amazon.com/config/latest/developerguide/cw-loggroup-retention-period-check.html
    EOM
  }

}
