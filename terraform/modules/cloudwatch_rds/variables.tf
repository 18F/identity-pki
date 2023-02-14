variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire."
}

variable "rds_db" {
  type        = string
  description = "ID of DB instance to create alarms for."
}

variable "db_instance_class" {
  type        = string
  description = "Instance class to monitor in RDS Cluster"
  default     = "db.r5.large"
}

variable "rds_storage_threshold" {
  type        = number
  description = <<EOM
DB instance storage (in bytes) to stay above before alerting.
Corresponds to FreeStorageSpace (for RDS) or FreeLocalStorage (for AuroraDB).
EOM
  default     = 100000000
}

variable "unvacummed_transactions_count" {
  type        = number
  description = "Maximum transaction IDs (count) that have been used by PostgreSQL."
  default     = 1000000000
}

variable "type" {
  description = "Type of database ('rds' or 'aurora') to create alarms for."
  type        = string
  default     = "rds"
  validation {
    condition     = contains(["rds", "aurora"], var.type)
    error_message = "DB type must be 'rds' or 'aurora'."
  }
}
