# Locals

locals {
  db_name = "${var.env_name}-${var.db_identifier}"

  cw_logs = var.cw_logs_exports == [] ? (
    can(regex("postgresql", var.db_engine)) ? ["postgresql"] : ["general"]
  ) : var.cw_logs_exports
}

# Identifiers

variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "db_identifier" {
  type        = string
  description = "Unique identifier for the database (e.g. default/primary/etc.)"
}

variable "db_name_override" {
  type        = string
  description = <<EOM
Manually-specified value for the database_name attribute of the Aurora cluster.
Defaults to 'postgres' for aurora-postgresql clusters if not specified.
EOM
  default     = ""
}

variable "create_global_db" {
  type        = bool
  description = <<EOM
Whether or not to enable creating an Aurora Global cluster AFTER the creation
of the aws_rds_cluster.aurora regional Aurora cluster. Must be set to 'false'
if this module instance is creating a secondary regional Aurora cluster
in an existing Global cluster.
EOM
  default     = false
}

variable "global_db_id" {
  type        = string
  description = <<EOM
Identifier for an Aurora Global cluster. MUST be specified if this module instance
is creating a secondary regional Aurora cluster in an existing Global cluster
OR if creating an Aurora Global cluster specifically within this module.
EOM
  default     = ""
}

# DB Engine/Parameter Config

variable "db_engine" {
  type        = string
  description = "AuroraDB engine name (aurora / aurora-mysql / aurora-postgresql)"
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  type        = string
  description = "Version number (e.g. ##.#) of db_engine to use"
  default     = "16.4"
}

variable "db_port" {
  type        = number
  description = "Database port number"
  default     = 5432
}

variable "apg_db_pgroup" {
  type        = string
  description = <<EOM
(REQUIRED) Name of an existing parameter group to use for the DB cluster instance(s).
EOM
}

variable "apg_cluster_pgroup" {
  type        = string
  description = <<EOM
(REQUIRED) Name of an existing parameter group to use for the DB cluster.
EOM
}

# Engine Mode/Instance Class

variable "db_engine_mode" {
  type        = string
  description = <<EOM
Engine mode for the AuroraDB cluster. Must be one of:
"global", "multimaster", "parallelquery", "provisioned", "serverless"
EOM
  default     = "provisioned"
}

variable "db_instance_class" {
  type        = string
  description = "Instance class to use in AuroraDB cluster"
  default     = "db.r6g.large"
}

variable "db_publicly_accessible" {
  type        = bool
  description = "Bool to control if instance is publicly accessible"
  default     = false
}

variable "serverlessv2_config" {
  type = list(object({
    max = number
    min = number
  }))
  description = <<EOM
(OPTIONAL) Configuration for Aurora Serverless v2 (if using)
which specifies min/max capacity, in a range of 0.5 up to 128 in steps of 0.5.
If configuring a Serverless v2 cluster/instances, you MUST set
var.db_engine_mode to 'provisioned' and var.db_instance_class to 'db.serverless'.
EOM
  default     = []
}

# Read Replicas / Auto Scaling

variable "primary_cluster_instances" {
  type        = number
  description = <<EOM
Number of instances to create for the primary AuroraDB cluster. MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
  default     = 1
  validation {
    condition = (
      var.primary_cluster_instances >= 1 &&
      var.primary_cluster_instances <= 15
    )
    error_message = "Cluster must contain between 1 and 15 instances."
  }
}

variable "enable_autoscaling" {
  type        = bool
  description = "Whether or not to enable Auto Scaling of read replica instances"
  default     = false
}

variable "max_cluster_instances" {
  type        = number
  description = <<EOM
Maximum number of read replica instances to scale up to
(if enabling Auto Scaling for the Aurora cluster)
EOM
  default     = 5
}

variable "autoscaling_metric_name" {
  type        = string
  description = <<EOM
Name of the predefined metric used by the Auto Scaling policy
(if enabling Auto Scaling for the Aurora cluster)
EOM
  default     = ""

  validation {
    condition = var.autoscaling_metric_name == "" || contains(
      [
        "RDSReaderAverageCPUUtilization", "RDSReaderAverageDatabaseConnections"
    ], var.autoscaling_metric_name)
    error_message = <<EOM
var.autoscaling_metric_name must be left blank, or be one of:
RDSReaderAverageCPUUtilization, RDSReaderAverageDatabaseConnections
EOM
  }
}

variable "autoscaling_metric_value" {
  type        = number
  description = <<EOM
Desired target value of Auto Scaling policy's predefined metric
(if enabling Auto Scaling for the Aurora cluster)
EOM
  default     = 40
}

# Logging/Monitoring

variable "cw_logs_exports" {
  type        = list(string)
  description = <<EOM
List of log types to export to CloudWatch. Will use ["general"] if not specified,
or ["postgresql"] if var.db_engine is "aurora-postgresql".
EOM
  default     = []
}

variable "cloudwatch_retention_days" {
  default     = 0
  description = <<EOM
Number of days to retain CloudWatch Logs for groups defined in var.cw_logs_exports
Defaults to 0 (never expire).
EOM
  type        = number
}

variable "pi_enabled" {
  type        = bool
  description = "Whether or not to enable Performance Insights on the Aurora cluster"
  default     = true
}

variable "monitoring_interval" {
  type        = number
  description = <<EOM
Time (in seconds) to wait before each metric sample collection.
Disabled if set to 0.
EOM
  default     = 60
}

variable "monitoring_role" {
  type        = string
  description = <<EOM
(OPTIONAL) Name of an existing IAM role with the AmazonRDSEnhancedMonitoringRole
service role policy attached. If left blank, will create the rds_monitoring IAM role
(which has said permission) within the module.
EOM
  default     = ""
}

# Maintenance/Upgrades

variable "auto_minor_upgrades" {
  type        = bool
  description = <<EOM
Whether or not to perform minor engine upgrades automatically during the
specified in the maintenance window. Defaults to false.
EOM
  default     = false
}

variable "major_upgrades" {
  type        = bool
  description = <<EOM
Whether or not to allow performing major version upgrades when
changing engine versions. Defaults to true.
EOM
  default     = true
}

variable "retention_period" {
  type        = number
  description = "Number of days to retain backups for"
  default     = 34
}

variable "backup_window" {
  type        = string
  description = "Daily time range (in UTC) for automated backups"
  default     = "08:00-08:34"
}

variable "maintenance_window" {
  type        = string
  description = "Weekly time range (in UTC) for scheduled/system maintenance"
  default     = "Sun:08:34-Sun:09:08"
}

# Networking

variable "db_security_group" {
  type        = string
  description = "(REQUIRED) VPC Security Group ID used by the AuroraDB cluster"
}

variable "db_subnet_group" {
  type        = string
  description = "(REQUIRED) Name of DB subnet group used by the AuroraDB cluster"
}

# Security/KMS

variable "storage_encrypted" {
  type        = bool
  description = "Whether or not to encrypt the underlying Aurora storage layer"
  default     = true
}

variable "db_kms_key_id" {
  type        = string
  description = <<EOM
(OPTIONAL) ID of an already-existing KMS Key used to encrypt the database;
will create the aws_kms_key.db / aws_kms_alias.db resources
and use those for encryption if left blank
EOM
  default     = ""
}

variable "key_admin_role_name" {
  type        = string
  description = <<EOM
(REQUIRED) Name of an external IAM role to be granted permissions
to interact with the KMS key used for encrypting the database
EOM
}

variable "rds_password" {
  type        = string
  description = "Password for the RDS master user account"
}

variable "rds_username" {
  type        = string
  description = "Username for the RDS master user account"
}

# Snapshot Management

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "Enables auto copying database tags to snapshots"
  default     = true
}

# Disaster Recovery

variable "dr_snapshot_identifier" {
  type        = string
  description = "Identifier of the database snapshot for snapshot recovery"
  default     = ""
}

variable "dr_restore_type" {
  type    = string
  default = ""

  validation {
    condition     = can(regex("^$|^(snapshot|point-in-time)$", var.dr_restore_type))
    error_message = "Invalid input, options: \"snapshot\", \"point-in-time\"."
  }
}

variable "dr_source_cluster_identifier" {
  type        = string
  description = "Identifier (name) of the source database for point-in-time recovery"
  default     = ""
}

variable "dr_restore_to_time" {
  type        = string
  description = "Timestamp for point-in-time recovery (2023-04-21T12:00:00Z)"
  default     = ""
}

variable "rds_ca_cert_identifier" {
  type        = string
  description = "Identifier of AWS RDS Certificate Authority Certificate"
  default     = "rds-ca-rsa2048-g1"
}
