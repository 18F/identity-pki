module "data_warehouse_export" {
  count                                 = var.enable_dms_analytics ? 1 : 0
  source                                = "../modules/data_warehouse_export"
  env_name                              = var.env_name
  account_id                            = data.aws_caller_identity.current.account_id
  data_warehouse_memory_usage_threshold = var.data_warehouse_memory_usage_threshold
  data_warehouse_duration_threshold     = var.data_warehouse_duration_threshold
  dms_logging_level                     = var.dms_logging_level
  region                                = var.region
  start_cw_export_task_lambda_schedule  = var.start_cw_export_task_lambda_schedule
  start_dms_task_lambda_schedule        = var.start_dms_task_lambda_schedule
  transform_cw_export_memory_size       = var.transform_cw_export_memory_size
  analytics_account_id                  = var.analytics_account_id
  lambda_insights_account               = var.lambda_insights_account
  idp_production_logs                   = aws_cloudwatch_log_group.log["idp_production"]
  idp_events_logs                       = aws_cloudwatch_log_group.log["idp_events"]
  low_priority_dw_alarm_actions         = local.low_priority_dw_alarm_actions
  dms_role                              = module.dms[0].dms_role
  network_acl_id                        = module.network_uw2.db_nacl_id
  inventory_bucket_arn                  = local.inventory_bucket_arn
  lambda_insights_version               = var.lambda_insights_version
  dms                                   = module.dms[0]
  cloudwatch_retention_days             = local.retention_days
}

moved {
  from = aws_cloudwatch_log_metric_filter.dms_filter_columns_metric[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_log_metric_filter.dms_filter_columns_metric
}

moved {
  from = aws_cloudwatch_event_rule.start_cw_export_task_schedule[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_event_rule.start_cw_export_task_schedule
}

moved {
  from = aws_cloudwatch_event_rule.start_dms_task_schedule[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_event_rule.start_dms_task_schedule
}

moved {
  from = aws_cloudwatch_event_target.start_cw_export_task[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_event_target.start_cw_export_task
}

moved {
  from = aws_cloudwatch_event_target.start_dms_task[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_event_target.start_dms_task
}

moved {
  from = aws_cloudwatch_metric_alarm.dms_filter_columns_alarm[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_metric_alarm.dms_filter_columns_alarm
}

moved {
  from = aws_cloudwatch_metric_alarm.s3_replication_failed_operations_analytics[0]
  to   = module.data_warehouse_export[0].aws_cloudwatch_metric_alarm.s3_replication_failed_operations_analytics
}

moved {
  from = aws_dms_replication_task.filtercolumns[0]
  to   = module.data_warehouse_export[0].aws_dms_replication_task.filtercolumns
}

moved {
  from = aws_dms_s3_endpoint.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_dms_s3_endpoint.analytics_export
}

moved {
  from = aws_iam_policy.replication[0]
  to   = module.data_warehouse_export[0].aws_iam_policy.replication
}

moved {
  from = aws_iam_role.replication[0]
  to   = module.data_warehouse_export[0].aws_iam_role.replication
}

moved {
  from = aws_iam_role.start_cw_export_task[0]
  to   = module.data_warehouse_export[0].aws_iam_role.start_cw_export_task
}

moved {
  from = aws_iam_role.start_dms_task[0]
  to   = module.data_warehouse_export[0].aws_iam_role.start_dms_task
}

moved {
  from = aws_iam_role.transform_cw_export[0]
  to   = module.data_warehouse_export[0].aws_iam_role.transform_cw_export
}

moved {
  from = aws_iam_role_policy.dms_s3[0]
  to   = module.data_warehouse_export[0].aws_iam_role_policy.dms_s3
}

moved {
  from = aws_iam_role_policy.start_cw_export_task[0]
  to   = module.data_warehouse_export[0].aws_iam_role_policy.start_cw_export_task
}

moved {
  from = aws_iam_role_policy.start_tasks[0]
  to   = module.data_warehouse_export[0].aws_iam_role_policy.start_tasks
}

moved {
  from = aws_iam_role_policy.transform[0]
  to   = module.data_warehouse_export[0].aws_iam_role_policy.transform
}

moved {
  from = aws_iam_role_policy_attachment.replication[0]
  to   = module.data_warehouse_export[0].aws_iam_role_policy_attachment.replication
}

moved {
  from = aws_lambda_function.start_cw_export_task[0]
  to   = module.data_warehouse_export[0].aws_lambda_function.start_cw_export_task
}

moved {
  from = aws_lambda_function.start_dms_task[0]
  to   = module.data_warehouse_export[0].aws_lambda_function.start_dms_task
}

moved {
  from = aws_lambda_function.transform_cw_export[0]
  to   = module.data_warehouse_export[0].aws_lambda_function.transform_cw_export
}

moved {
  from = aws_lambda_permission.allow_events_bridge_to_run_lambda[0]
  to   = module.data_warehouse_export[0].aws_lambda_permission.allow_events_bridge_to_run_lambda
}

moved {
  from = aws_lambda_permission.start_dms_task_allow_events_bridge_to_run_lambda[0]
  to   = module.data_warehouse_export[0].aws_lambda_permission.start_dms_task_allow_events_bridge_to_run_lambda
}

moved {
  from = aws_lambda_permission.transform_cw_export_s3_events[0]
  to   = module.data_warehouse_export[0].aws_lambda_permission.transform_cw_export_s3_events
}

moved {
  from = aws_network_acl_rule.db-egress-s3-https
  to   = module.data_warehouse_export[0].aws_network_acl_rule.db-egress-s3-https
}

moved {
  from = aws_network_acl_rule.db-ingress-s3-ephemeral
  to   = module.data_warehouse_export[0].aws_network_acl_rule.db-ingress-s3-ephemeral
}

moved {
  from = aws_s3_bucket.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket.analytics_export
}

moved {
  from = aws_s3_bucket_acl.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_acl.analytics_export
}

moved {
  from = aws_s3_bucket_notification.trigger_transform[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_notification.trigger_transform
}

moved {
  from = aws_s3_bucket_ownership_controls.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_ownership_controls.analytics_export
}

moved {
  from = aws_s3_bucket_policy.analytics_export_allow_export_tasks[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_policy.analytics_export_allow_export_tasks
}

moved {
  from = aws_s3_bucket_public_access_block.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_public_access_block.analytics_export
}

moved {
  from = aws_s3_bucket_replication_configuration.to_analytics[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_replication_configuration.to_analytics
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_server_side_encryption_configuration.analytics_export
}

moved {
  from = aws_s3_bucket_versioning.analytics_export[0]
  to   = module.data_warehouse_export[0].aws_s3_bucket_versioning.analytics_export
}

moved {
  from = module.analytics_export_bucket_config[0].aws_s3_bucket_inventory.daily
  to   = module.data_warehouse_export[0].module.analytics_export_bucket_config.aws_s3_bucket_inventory.daily
}

moved {
  from = module.analytics_export_bucket_config[0].aws_s3_bucket_public_access_block.public_block
  to   = module.data_warehouse_export[0].module.analytics_export_bucket_config.aws_s3_bucket_public_access_block.public_block
}

moved {
  from = module.start_cw_export_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_duration[0]
  to   = module.data_warehouse_export[0].module.start_cw_export_task_alerts.aws_cloudwatch_metric_alarm.lambda_duration[0]
}

moved {
  from = module.start_cw_export_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_error_rate[0]
  to   = module.data_warehouse_export[0].module.start_cw_export_task_alerts.aws_cloudwatch_metric_alarm.lambda_error_rate[0]
}

moved {
  from = module.start_cw_export_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
  to   = module.data_warehouse_export[0].module.start_cw_export_task_alerts.aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
}

moved {
  from = module.start_cw_export_task_code[0].null_resource.source_hash_check
  to   = module.data_warehouse_export[0].module.start_cw_export_task_code.null_resource.source_hash_check
}

moved {
  from = module.start_dms_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_duration[0]
  to   = module.data_warehouse_export[0].module.start_dms_task_alerts.aws_cloudwatch_metric_alarm.lambda_duration[0]
}

moved {
  from = module.start_dms_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_error_rate[0]
  to   = module.data_warehouse_export[0].module.start_dms_task_alerts.aws_cloudwatch_metric_alarm.lambda_error_rate[0]
}

moved {
  from = module.start_dms_task_alerts[0].aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
  to   = module.data_warehouse_export[0].module.start_dms_task_alerts.aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
}

moved {
  from = module.start_dms_task_code[0].null_resource.source_hash_check
  to   = module.data_warehouse_export[0].module.start_dms_task_code.null_resource.source_hash_check
}

moved {
  from = module.transform_cw_export_alerts[0].aws_cloudwatch_metric_alarm.lambda_duration[0]
  to   = module.data_warehouse_export[0].module.transform_cw_export_alerts.aws_cloudwatch_metric_alarm.lambda_duration[0]
}

moved {
  from = module.transform_cw_export_alerts[0].aws_cloudwatch_metric_alarm.lambda_error_rate[0]
  to   = module.data_warehouse_export[0].module.transform_cw_export_alerts.aws_cloudwatch_metric_alarm.lambda_error_rate[0]
}

moved {
  from = module.transform_cw_export_alerts[0].aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
  to   = module.data_warehouse_export[0].module.transform_cw_export_alerts.aws_cloudwatch_metric_alarm.lambda_memory_usage[0]
}

moved {
  from = module.transform_cw_export_code[0].null_resource.source_hash_check
  to   = module.data_warehouse_export[0].module.transform_cw_export_code.null_resource.source_hash_check
}

