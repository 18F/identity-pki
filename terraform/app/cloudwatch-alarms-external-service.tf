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
  alarm_description         = <<EOM
LN Instant Verify 90th pecentile response time in ${var.env_name} has been greater than 10 seconds for 3 minutes

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
EOM
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
  alarm_description         = <<EOM
LN Phone Finder 90th pecentile response time in ${var.env_name} has been greater than 10 seconds for 3 minutes

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
EOM
  treat_missing_data        = "ignore"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_acuant_create_document_response_time_high_alarm" {
  count = var.idp_external_service_alarms_enabled

  alarm_name          = "${var.env_name}-acuant-create-document-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  metric_name         = "faraday-response-time"
  namespace           = "${var.env_name}/idp-external-service"
  period              = "60"
  extended_statistic  = "p50"
  dimensions = {
    Service = "acuant_doc_auth_create_document"
  }
  threshold                 = "5"
  alarm_description         = <<EOM
Acuant Create Document 50th pecentile response time in ${var.env_name} has been greater than 5 seconds for 3 minutes

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
EOM
  treat_missing_data        = "ignore"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}
