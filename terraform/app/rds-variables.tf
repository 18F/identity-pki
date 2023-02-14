# Locals

locals {
  # DB parameter groups are defined here and divided into instance-only parameters,
  # cluster-only parameters, or both, for Aurora support
  apg_cluster_pgroup_params = [
    {
      name   = "rds.force_ssl"
      value  = "1"
      method = "pending-reboot"
    },
    # Log autovacuum tasks that take more than 1 sec
    {
      name  = "rds.force_autovacuum_logging_level"
      value = "log"
    },
    {
      name  = "log_autovacuum_min_duration"
      value = 1000
    },
    # BigInt: Set logical replication for change data capture (cdc)
    {
      name   = "rds.logical_replication"
      value  = var.enable_dms_migration ? "1" : "0",
      method = "pending-reboot"
    },
    # Aurora maxes out at 30000 ms
    # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
    {
      name  = "max_standby_streaming_delay"
      value = "30000"
    }
  ]

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

variable "rds_engine_aurora" {
  type        = string
  description = "AuroraDB engine name (aurora / aurora-mysql / aurora-postgresql)"
  default     = "aurora-postgresql"
}

variable "rds_engine_version_aurora" {
  type        = string
  description = "Version number (e.g. ##.#) of db_engine to use"
  default     = "13.9"
}

variable "rds_instance_class_aurora" {
  type        = string
  description = <<EOM
Instance class to use for the 'login-ENV-idp-aurora-us-west-2' AuroraDB cluster.
EOM
  default     = "db.t3.medium"
}

variable "rds_password" { # set manually after creation
}

variable "rds_username" { # set manually after creation
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

variable "rds_recover_to_ue1" {
  type        = bool
  description = <<EOM
Whether or not to create DB parameter groups/KMS CMKs
in us-east-1 via the idp_rds_use1 module.
Defaults to false ; should be manually set to true in upper environments.
EOM
  default     = false
}

variable "rds_engine_mode_aurora" {
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

variable "performance_insights_enabled" {
  default     = "true"
  description = "Enables Performance Insights on RDS"
}

# idp

variable "idp_aurora_enabled" {
  type        = bool
  description = <<EOM
Enable/disable creation of the 'login-ENV-idp-aurora-us-west-2' AuroraDB cluster.
Set to FALSE once new ENV-idp cluster (w/BigInt changes) has replaced it.
EOM
  default     = true
}

variable "idp_cluster_instances" {
  type        = number
  description = <<EOM
Number of instances to create for the idp AuroraDB cluster(s). MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
  default     = 1
  validation {
    condition = (
      var.idp_cluster_instances >= 1 &&
      var.idp_cluster_instances <= 15
    )
    error_message = "Cluster must contain between 1 and 15 instances."
  }
}

variable "idp_aurora_autoscaling" {
  type        = bool
  description = "Enable/disable Auto Scaling for the idp Aurora DB cluster(s)"
  default     = false
}

variable "idp_aurora_serverlessv2_config" {
  type = list(object({
    max = number
    min = number
  }))
  description = <<EOM
Scaling configuration (maximum/minimum capacity) to use,
if setting/upgrading idp DB cluster to Aurora Serverless v2
EOM
  default     = []
}

# dashboard (app)

variable "rds_instance_class_dashboard_aurora" {
  type        = string
  description = "Instance class for dashboard Aurora DB cluster"
  default     = "db.t3.medium"
}

variable "dashboard_aurora_pgroup" {
  type        = string
  description = <<EOM
Name of the default parameter group for the dashboard Aurora DB cluster/instance(s);
should match main number of var.rds_engine_version
EOM
  default     = "default.aurora-postgresql13"
}

variable "dashboard_cluster_instances" {
  type        = number
  description = "Number of instances in the dashboard Aurora DB cluster."
  default     = 1
  validation {
    condition = (
      var.dashboard_cluster_instances >= 1 &&
      var.dashboard_cluster_instances <= 15
    )
    error_message = "Cluster must contain between 1 and 15 instances."
  }
}

variable "dashboard_aurora_autoscaling" {
  description = "Enable/disable Auto Scaling for the dashboard Aurora DB cluster"
  type        = bool
  default     = false
}

variable "dashboard_aurora_serverlessv2_config" {
  type = list(object({
    max = number
    min = number
  }))
  description = <<EOM
Scaling configuration (maximum/minimum capacity) to use,
if setting/upgrading dashboard DB cluster to Aurora Serverless v2
EOM
  default     = []
}

# worker

variable "rds_engine_version_worker_jobs_aurora" {
  type        = string
  description = "db_engine to use for worker Aurora DB cluster"
  default     = "13.9"
}

variable "rds_instance_class_worker_jobs_aurora" {
  type        = string
  description = "Instance class for worker Aurora DB cluster"
  default     = "db.t3.medium"
}

variable "rds_password_worker_jobs" {
}

variable "rds_username_worker_jobs" {
}

variable "worker_cluster_instances" {
  type        = number
  description = "Number of instances in the worker Aurora DB cluster."
  default     = 1
  validation {
    condition = (
      var.worker_cluster_instances >= 1 &&
      var.worker_cluster_instances <= 15
    )
    error_message = "Cluster must contain between 1 and 15 instances."
  }
}

variable "worker_aurora_autoscaling" {
  description = "Enable/disable Auto Scaling for the worker Aurora DB cluster"
  type        = bool
  default     = false
}

variable "worker_jobs_aurora_serverlessv2_config" {
  type = list(object({
    max = number
    min = number
  }))
  description = <<EOM
Scaling configuration (maximum/minimum capacity) to use,
if setting/upgrading worker DB cluster to Aurora Serverless v2
EOM
  default     = []
}
