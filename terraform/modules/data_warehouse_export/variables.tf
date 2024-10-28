locals {
  analytics_import_bucket = join("-", [
    "login-gov-redshift-import-${var.env_name}",
    "${var.analytics_account_id}-${var.region}"
  ])

  analytics_import_arn             = "arn:aws:s3:::${local.analytics_import_bucket}"
  transform_cw_export_lambda_name  = "${var.env_name}-transform-cw-export"
  start_dms_task_lambda_name       = "${var.env_name}-start-dms-task"
  start_cw_export_task_lambda_name = "${var.env_name}-start-cw-export"

  lambda_insights = "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer:LambdaInsightsExtension:${var.lambda_insights_version}"

  analytics_target_log_groups = [
    {
      resource     = var.idp_production_logs,
      json_encoded = "true"
    },
    {
      resource     = var.idp_events_logs,
      json_encoded = "true"
    }
  ]

  data_warehouse_lambda_alerts_runbooks = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#lambda-alerts"

}


variable "env_name" {
  type        = string
  description = ""
  default     = ""
}

variable "region" {
  default = "us-west-2"
}

variable "data_warehouse_memory_usage_threshold" {
  type        = number
  description = "The threshold memory utilization (as a percentage) for triggering an alert"
  default     = 90
}

variable "data_warehouse_duration_threshold" {
  type        = number
  description = "The duration threshold (as a percentage) for triggering an alert"
  default     = 80
}

variable "dms_logging_level" {
  type        = string
  description = "Sets logging level for the dms migration instances"
  default     = "LOGGER_SEVERITY_INFO"
}

variable "start_cw_export_task_lambda_schedule" {
  type        = string
  default     = "rate(1 day)"
  description = "Determines the schedule to execute the export lambda. Supports rate expression and cron expression"
}

variable "start_dms_task_lambda_schedule" {
  type        = string
  default     = "rate(1 day)"
  description = "Determines the schedule to execute the export lambda. Supports rate expression and cron expression"
}

variable "transform_cw_export_memory_size" {
  description = "Defines the amount of memory in MB the transform_cw_export lambda can use at runtime"
  type        = number
  default     = 128
}

variable "analytics_account_id" {
  type        = string
  default     = "487317109730"
  description = "The associated analytics account to use. Defaults to analytics-sandbox"
}

variable "lambda_insights_account" {
  description = "The lambda insights account provided by AWS for monitoring"
  type        = string
  default     = "580247275435"
}

variable "idp_production_logs" {
  type = object({
    arn  = string
    name = string
  })
  description = "Log group for idp production logs"
}

variable "idp_events_logs" {
  type = object({
    arn  = string
    name = string
  })
  description = "Log group for idp events logs"
}

variable "account_id" {
  type        = number
  description = "The current account id"
}

variable "low_priority_dw_alarm_actions" {
  type        = list(any)
  description = "List of arns for low-priority data warehouse alarm actions"
}

variable "dms_role" {
  type = object({
    name = string
    arn  = string
  })
  description = "DMS Iam role"
}

variable "network_acl_id" {
  type        = string
  description = "NACL id"
}

variable "inventory_bucket_arn" {
  type        = string
  description = "arn for inventory bucket"
}

variable "lambda_insights_version" {
  description = "The lambda insights layer version to use for monitoring"
  type        = number
  default     = 38
}

variable "dms" {
  type = object({
    dms_replication_instance_arn = string
    dms_source_endpoint_arn      = string
    dms_log_group                = string
  })
  description = "Information about the DMS instane"
}



