variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

variable "rds_db" {
  type        = string
  description = "ID of RDS database to create alarms for"
}

variable "rds_storage_threshold" {
  description = "RDS instance free storage (in bytes) to stay above before alerting"
  type        = string
  default     = "100000000"
}

variable "unvacummed_transactions_count" {
  description = "The maximum transaction IDs(in count) that have been used by PostgreSQL."
  type        = string
  default     = "1000000000"
}
