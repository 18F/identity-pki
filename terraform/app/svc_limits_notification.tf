module "limit_check_lambda" {
  source                     = "../modules/monitor_svc_limit"
  refresher_trigger_schedule = var.refresher_trigger_schedule
  monitor_trigger_schedule   = var.monitor_trigger_schedule
  aws_region                 = var.region
  sns_topic                  = local.low_priority_alarm_actions
}


resource "aws_cloudwatch_metric_alarm" "kms_api" {
  alarm_name                = "kms_api_limit_check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "10"
  threshold                 = "80"
  alarm_description         = "KMS Cryptographic operations (symmetric) api request rate has exceeded 80%"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = local.low_priority_alarm_actions


  metric_query {
    id          = "pct_utilization"
    expression  = "(usage_data/SERVICE_QUOTA(usage_data))*100"
    label       = "% Utilization"
    return_data = "true"
  }

  metric_query {
    id          = "usage_data"
    return_data = "false"
    metric {
      metric_name = "CallCount"
      namespace   = "AWS/Usage"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        Class    = "None"
        Resource = "CryptographicOperationsSymmetric"
        Service  = "KMS"
        Type     = "API"
      }
    }
  }
}
