locals {
  reporting_worker_filters = {
    reporting_worker_perform_success = {
      name         = "perform-success"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message NOT EXISTS && $.queue_name = \"*GoodJob*\" }"
      metric_value = 1
    },
    reporting_worker_perform_failure = {
      name         = "perform-failure"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message = * && $.queue_name = \"*GoodJob*\" && $.queue_name != \"*long_running*\" }"
      metric_value = 1
    },
    reporting_data_out_of_range = {
      name         = "data-freshness-out-of-range"
      pattern      = "{ $.name = \"DataFreshnessJob\" && ($.status = \"out_of_range\" || $.error = \"No logs found!\") }"
      metric_value = 1
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "reporting_worker" {
  for_each       = local.reporting_worker_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.log["reporting_workers"].name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/reporting-worker"
    value     = each.value["metric_value"]
  }
}
