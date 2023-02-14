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

  # Set to 1800000 ms (30 min) for RDS; Aurora maxes out at 30000 ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  apg_param_max_standby_streaming_delay = {
    name  = "max_standby_streaming_delay"
    value = "30000"
  }
  rds_param_max_standby_streaming_delay = {
    name  = "max_standby_streaming_delay"
    value = "1800000"
  }
}

# General / All DBs

variable "rds_backup_retention_period" {
  default = "34"
}

variable "rds_backup_window" {
  default = "08:00-08:34"
}

variable "rds_db_port" {
  default = 5432
}

variable "rds_engine" {
  default = "postgres"
}

variable "rds_engine_aurora" {
  default = "aurora-postgresql"
}

variable "rds_engine_version" {
  default = "13.5"
}

variable "rds_engine_version_aurora" {
  default = "13.9"
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}

variable "rds_instance_class_aurora" {
  default = "db.t3.medium"
}

variable "rds_password" { # set manually after creation
}

variable "rds_username" { # set manually after creation
}

variable "rds_maintenance_window" {
  default = "Sun:08:34-Sun:09:08"
}

variable "rds_enhanced_monitoring_interval" {
  description = "How many seconds to wait before each metric sample collection - Set to 0 to disable"
  type        = number
  default     = 60
}

variable "rds_monitoring_role_name" {
  default = "rds-monitoring-role"
}

variable "rds_dashboard_idp_vertical_annotations" {
  description = "A raw JSON array of vertical annotations to add to all cloudwatch dashboard widgets"
  default     = "[]"
}

variable "rds_storage_threshold" {
  description = "RDS instance free storage (in bytes) to stay above before alerting"
  default     = "100000000"
}

variable "rds_recover_to_ue1" {
  description = <<EOM
Whether or not to create a DB parameter group in us-east-1 via the idp_rds_use1 module.
Defaults to false ; should be manually set to true in upper environments.
EOM
  type        = bool
  default     = false
}

variable "rds_engine_mode_aurora" {
  type        = string
  description = "DB engine mode to use with Aurora DB cluster(s)"
  default     = "provisioned"
}

# idp

variable "idp_use_rds" {
  description = <<EOM
Whether or not to build/use an AWS RDS instance (vs. AuroraDB) for the IdP DB.
Set to false if wanting to spin down and/or not create the RDS DB.
EOM
  type        = bool
  default     = true
}

variable "rds_storage_type_idp" {
  # possible storage types:
  # standard (magnetic)
  # gp2 (general SSD)
  # io1 (provisioned IOPS SSD)
  description = "EBS storage type (magnetic, SSD, PIOPS) used by the idp RDS database"
  default     = "standard"
}

variable "rds_iops_idp" {
  description = "If PIOPS storage is used, the number of IOPS provisioned"
  default     = 0
}

variable "rds_storage_idp" {
  default = "26"
}

variable "idp_aurora_enabled" {
  type        = bool
  description = "Enable/disable creating idp AuroraDB cluster"
  default     = true
}

variable "idp_cluster_instances" {
  type        = number
  description = <<EOM
Number of instances to create for the idp AuroraDB cluster. MUST be Set to 1
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
  description = "Enable/disable Auto Scaling for the idp Aurora DB cluster"
  type        = bool
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

# idp-replica

variable "enable_rds_idp_read_replica" {
  description = "Whether to create an RDS read replica of the idp RDS database"
  default     = false
  type        = bool
}

variable "rds_engine_version_replica" {
  default     = "13.5"
  description = <<EOM
rds_engine_version for idp-replica RDS database.
RDS requires that replicas be upgraded *before* primaries
EOM
}

variable "rds_instance_class_replica" {
  default = "db.t3.micro"
}

variable "rds_storage_type_idp_replica" {
  description = <<EOM
EBS storage type (magnetic, SSD, PIOPS) used by idp-replica RDS database
EOM
  default     = "standard"
}

variable "rds_iops_idp_replica" {
  description = <<EOM
If PIOPS storage is used, number of IOPS provisioned for idp-replica RDS database
EOM
  default     = 0
}

variable "rds_storage_idp_replica" {
  default = "26"
}

# dashboard (app)

variable "dashboard_use_rds" {
  description = <<EOM
Whether or not to build/use an AWS RDS instance (vs. AuroraDB) for the dashboard DB.
Set to false if wanting to spin down and/or not create the RDS DB.
EOM
  type        = bool
  default     = true
}

variable "rds_instance_class_dashboard_aurora" {
  default = "db.t3.medium"
}

variable "rds_storage_app" {
  default = "8"
}

variable "dashboard_aurora_enabled" {
  type        = bool
  description = "Enable/disable creating dashboard AuroraDB cluster"
  default     = false
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
  description = <<EOM
Number of instances to create for the dashboard AuroraDB cluster. MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
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

# worker (idp-worker-jobs)

variable "worker_use_rds" {
  description = <<EOM
Whether or not to build/use an AWS RDS instance (vs. AuroraDB) for the worker-jobs DB.
Set to false if wanting to spin down and/or not create the RDS DB.
EOM
  type        = bool
  default     = true
}

variable "rds_engine_version_worker_jobs" {
  default = "13.5"
}

variable "rds_engine_version_worker_jobs_aurora" {
  default = "13.9"
}

variable "rds_instance_class_worker_jobs" {
  default = "db.t3.micro"
}

variable "rds_instance_class_worker_jobs_aurora" {
  default = "db.t3.medium"
}

variable "rds_storage_type_idp_worker_jobs" {
  description = <<EOM
EBS storage type (magnetic, SSD, PIOPS) used by idp-worker-jobs RDS database
EOM
  default     = "gp2"
}

variable "rds_iops_idp_worker_jobs" {
  description = <<EOM
If PIOPS storage is used, number of IOPS provisioned for idp-worker-jobs RDS database
EOM
  default     = 0
}

variable "rds_password_worker_jobs" {
}

variable "rds_storage_idp_worker_jobs" {
  default = "8"
}

variable "rds_username_worker_jobs" {
}

variable "worker_aurora_enabled" {
  type        = bool
  description = "Enable/disable creating idp-worker-jobs AuroraDB cluster"
  default     = false
}

variable "worker_cluster_instances" {
  type        = number
  description = <<EOM
Number of instances to create for the worker AuroraDB cluster. MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
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
if setting/upgrading worker_jobs DB cluster to Aurora Serverless v2
EOM
  default     = []
}
