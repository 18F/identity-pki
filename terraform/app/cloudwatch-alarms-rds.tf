### Cloudwatch Alarm montioring PostgreSql Database's unvacummed transaction ids and send alert to high priority alarm actions to avoid autovacuum ###

module "cloudwatch_alarm_rds" {
  source = "../modules/cloudwatch_rds/"

  rds_storage_threshold = var.unvacummed_transactions_count
  rds_db                = var.rds_db
  alarm_actions         = local.high_priority_alarm_actions
}
