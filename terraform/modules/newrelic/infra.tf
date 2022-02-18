resource "newrelic_infra_alert_condition" "memory_alert" {
  count      = var.low_memory_alert_enabled
  policy_id  = var.env_name == "prod" ? newrelic_alert_policy.high[0].id : newrelic_alert_policy.low[0].id
  name       = "${var.env_name}: DASHBOARD LOW Memory Alert"
  type       = "infra_metric"
  event      = "SystemSample"
  select     = "memoryFreeBytes"
  comparison = "below"
  where      = "(hostname LIKE '%${var.error_dashboard_site}%')"

  critical {
    duration      = 5
    value         = var.memory_free_threshold_byte
    time_function = "all"
  }
}
