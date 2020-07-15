variable "enable_rds_idp_read_replica" {
  description = "Whether to create an RDS read replica of the IDP database"
  default     = false
  # TODO: TF 0.12
  # type = bool
}

variable "rds_backup_retention_period" {
  default = "34"
}

variable "rds_backup_window" {
  default = "08:00-08:34"
}

# Changing engine or engine_version requires also changing any relevant uses of
# aws_db_parameter_group, which has a family attribute that tightly couples its
# parameter to the engine and version.

variable "rds_engine" {
  default = "postgres"
}

variable "rds_engine_version" {
  default = "9.6.18"
}

variable "rds_engine_version_replica" {
  default     = "9.6.18"
  description = "RDS requires that replicas be upgraded *before* primaries"
}

variable "rds_engine_version_short" {
  default = "9.6"
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}

variable "rds_instance_class_replica" {
  default = "db.t3.micro"
}

variable "rds_storage_type_idp" {
  # possible storage types:
  # standard (magnetic)
  # gp2 (general SSD)
  # io1 (provisioned IOPS SSD)
  description = "The type of EBS storage (magnetic, SSD, PIOPS) used by the IdP database"
  default     = "standard"
}

variable "rds_storage_type_idp_replica" {
  description = "The type of EBS storage (magnetic, SSD, PIOPS) used by the IdP database read replica"
  default     = "standard"
}

variable "rds_iops_idp" {
  description = "If PIOPS storage is used, the number of IOPS provisioned"

  # Terraform doesn't distinguish between 0 and unset / TODO TF 0.12
  default = 0
}

variable "rds_iops_idp_replica" {
  description = "If PIOPS storage is used, the number of IOPS provisioned for the read replica"

  # Terraform doesn't distinguish between 0 and unset / TODO TF 0.12
  default = 0
}

variable "rds_password" {
}

variable "rds_storage_app" {
  default = "8"
}

variable "rds_storage_idp" {
  default = "8"
}

variable "rds_storage_idp_replica" {
  default = "8"
}

variable "rds_username" {
}

variable "rds_maintenance_window" {
  default = "Sun:08:34-Sun:09:08"
}

variable "rds_enhanced_monitoring_enabled" {
  default = 1
}

variable "rds_monitoring_role_name" {
  default = "rds-monitoring-role"
}

variable "rds_dashboard_idp_vertical_annotations" {
  description = "A raw JSON array of vertical annotations to add to all cloudwatch dashboard widgets"
  default     = "[]"
}

