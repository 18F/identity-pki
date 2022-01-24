resource "aws_cloudwatch_metric_alarm" "idp_lexis_nexis_instant_verify_response_time_high_alarm" {
  count = var.idp_external_service_alarms_enabled

  alarm_name          = "${var.env_name}-lexis-nexis-instant-verify-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  metric_name         = "faraday-response-time"
  namespace           = "${var.env_name}/idp-external-service"
  period              = "60"
  extended_statistic  = "p90"
  dimensions = {
    Service = "lexis_nexis_instant_verify"
  }
  threshold                 = "10"
  alarm_description         = "LN Instant Verify 90th pecentile response time in ${var.env_name} has been greater than 10 seconds for 3 minutes"
  treat_missing_data        = "ignore"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_lexis_nexis_phone_finder_response_time_high_alarm" {
  count = var.idp_external_service_alarms_enabled

  alarm_name          = "${var.env_name}-lexis-nexis-phone-finder-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  metric_name         = "faraday-response-time"
  namespace           = "${var.env_name}/idp-external-service"
  period              = "60"
  extended_statistic  = "p90"
  dimensions = {
    Service = "lexis_nexis_phone_finder"
  }
  threshold                 = "10"
  alarm_description         = "LN Phone Finder 90th pecentile response time in ${var.env_name} has been greater than 10 seconds for 3 minutes"
  treat_missing_data        = "ignore"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}
