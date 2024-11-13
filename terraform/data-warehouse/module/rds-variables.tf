# Locals

locals {
  # DB parameter groups are defined here and divided into instance-only parameters,
  # cluster-only parameters, or both, for Aurora support
  apg_cluster_pgroup_params = flatten([
    [
      {
        name   = "rds.force_ssl",
        value  = "1",
        method = "pending-reboot"
      },
      # Log autovacuum tasks that take more than 1 sec
      {
        name  = "rds.force_autovacuum_logging_level",
        value = "log"
      },
      {
        name  = "log_autovacuum_min_duration",
        value = 1000
      },
      # Aurora maxes out at 30000 ms
      # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
      {
        name  = "max_standby_streaming_delay",
        value = "30000"
      },
      {
        name  = "password_encryption",
        value = "md5"
      }
    ],
  ])

  apg_db_pgroup_params = [
    # Log all Data Definition Layer changes (ALTER, CREATE, etc.)
    {
      name  = "log_statement"
      value = "ddl"
    },
    # Log all slow queries that take longer than specified time in ms
    {
      name  = "log_min_duration_statement"
      value = "250" # 250 ms
    },
    # Log lock waits
    {
      name  = "log_lock_waits"
      value = "1"
    }
  ]
}

# General / All DBs

variable "rds_backup_retention_period" {
  type        = number
  description = "Number of days to retain backups for"
  default     = 34
}

variable "rds_backup_window" {
  type        = string
  description = "Daily time range (in UTC) for automated backups"
  default     = "08:00-08:34"
}

variable "rds_db_port" {
  type        = number
  description = "Database port number"
  default     = 5432
}

variable "rds_engine" {
  type        = string
  description = "AuroraDB engine name (aurora / aurora-mysql / aurora-postgresql)"
  default     = "aurora-postgresql"
}

variable "rds_engine_version" {
  type        = string
  description = "Version number (e.g. ##.#) of rds_engine to use in us-west-2"
  default     = "16.4"
}

variable "rds_instance_class" {
  type        = string
  description = <<EOM
Instance class to use for the idp AuroraDB cluster(s). Will be ignored
in favor of rds_instance_class_global if idp_global_enabled is 'true',
as Aurora clusters MUST have an instance class of db.r5.large (the default
value) or larger in order to support a Global cluster.
EOM
  default     = "db.t3.medium"
}

variable "rds_instance_class_global" {
  type        = string
  description = <<EOM
Instance class to use for the idp AuroraDB cluster(s) when creating/supporting
a Global Aurora cluster. MUST be an instance class of db.r5.large or larger.
Will override rds_instance_class if if idp_global_enabled is 'true'.
EOM
  default     = "db.r5.large"
}

variable "rds_password" { # set manually after creation
  type    = string
  default = "Zero-Inconvenience"
}

variable "rds_username" { # set manually after creation
  type    = string
  default = "analytics"
}

variable "rds_maintenance_window" {
  type        = string
  description = "Weekly time range (in UTC) for scheduled/system maintenance"
  default     = "Sun:08:34-Sun:09:08"
}

variable "rds_enhanced_monitoring_interval" {
  type        = number
  description = <<EOM
Time (in seconds) to wait before each metric sample collection.
Disabled if set to 0.
EOM
  default     = 60
}

variable "rds_monitoring_role_name" {
  type        = string
  description = "IAM role with the AmazonRDSEnhancedMonitoringRole policy attached."
  default     = "rds-monitoring-role"
}

variable "rds_storage_threshold" {
  type        = number
  description = "RDS instance free storage (in bytes) to stay above before alerting"
  default     = 100000000
}

variable "rds_engine_mode" {
  type        = string
  description = "DB engine mode to use with Aurora DB cluster(s)"
  default     = "provisioned"
}

variable "enable_dms_migration" {
  type        = bool
  description = <<EOM
Enables creation of resources necessary for migrating idp databases
from integer columns to BigInt columns.
EOM
  default     = false
}

variable "unvacummed_transactions_count" {
  type        = string
  description = "Maximum transaction IDs (in count) used by PostgreSQL."
  default     = 1000000000
}

variable "analytics_cluster_instances" {
  type        = number
  description = "Number of instances in the analytics Aurora DB cluster."
  default     = 1
  validation {
    condition = (
      var.analytics_cluster_instances >= 1 &&
      var.analytics_cluster_instances <= 15
    )
    error_message = "Cluster must contain between 1 and 15 instances."
  }
}

variable "analytics_aurora_autoscaling" {
  description = "Enable/disable Auto Scaling for the analytics Aurora DB cluster"
  type        = bool
  default     = false
}

variable "analytics_serverlessv2_config" {
  type = list(object({
    max = number
    min = number
  }))
  description = <<EOM
Scaling configuration (maximum/minimum capacity) to use,
if setting/upgrading analytics DB cluster to Aurora Serverless v2
EOM
  default     = []
}

variable "rds_ca_cert_identifier" {
  type        = string
  description = "Identifier of AWS RDS Certificate Authority Certificate"
  default     = "rds-ca-rsa2048-g1"
}
