# Iterate over vendors (in variables.tf) creating alarms for:
# AAMVA, Instant Verify, Pinpoint, & TrueID
resource "aws_cloudwatch_metric_alarm" "doc_auth_vendor_exception_rate" {
  for_each = var.idp_external_service_alarms_enabled == 1 ? var.doc_auth_vendors : {}

  alarm_name        = "${aws_autoscaling_group.idp.name}-doc-auth-vendor-exception-rate-${each.key}"
  alarm_description = <<EOM
${aws_autoscaling_group.idp.name}: ${each.value.long_name} idv vendor
exception rate is above 50% over a period of 15 mins.

%{if each.value.runbook_url != ""~}
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-${each.value.runbook_url}
%{else~}
Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
%{endif~}
%{if var.env_name == "prod" && length(each.value.slack_oncall_handles) > 0}
Notifying: ${join(", ", each.value.slack_oncall_handles)}
%{endif}
EOM

  metric_query {
    id          = "exception_rate_${each.key}"
    expression  = "(exc${each.key} / all${each.key}) * 100"
    label       = "Exception rate of ${each.value.long_name}"
    return_data = "true"
  }

  metric_query {
    id = "exc${each.key}"

    metric {
      metric_name = "doc-auth-vendor-exception-${each.key}"
      namespace   = "${var.env_name}/idp-ialx"
      period      = 900
      stat        = "Sum"
    }
  }

  metric_query {
    id = "all${each.key}"

    metric {
      metric_name = "doc-auth-vendor-overall-${each.key}"
      namespace   = "${var.env_name}/idp-ialx"
      period      = 900
      stat        = "Sum"
    }
  }

  alarm_actions       = local.doc_auth_alarm_actions
  comparison_operator = "GreaterThanThreshold"
  threshold           = 50
  evaluation_periods  = each.value.evaluation_periods
}

resource "aws_cloudwatch_metric_alarm" "idv_high_proofing_resolution_result_missing" {
  alarm_name        = "${aws_autoscaling_group.idp.name}-idv-proofing-resolution-result-missing-rate"
  alarm_description = <<EOM
${aws_autoscaling_group.idp.name}: IdV: proofing resolution result missing
rate is above ${var.idv_high_proofing_resolution_result_missing_threshold} occurrences over a period of 15 mins.

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html#proofing-resolution-result-missing-alert
%{if var.env_name == "prod"}
Notifying:%{for handle in var.slack_proofing_groups} @${handle}%{endfor}
%{endif}
EOM

  metric_name = "idv-proofing-resolution-result-missing"
  namespace   = "${var.env_name}/idp-ialx"
  period      = 900
  statistic   = "Sum"

  alarm_actions       = local.moderate_priority_alarm_actions
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.idv_high_proofing_resolution_result_missing_threshold
  evaluation_periods  = 1
}

resource "aws_cloudwatch_metric_alarm" "idv_unexpected_face_match_errors" {
  alarm_name        = "${aws_autoscaling_group.idp.name}-idv-unexpected-face-match-error-rate"
  alarm_description = <<EOM
${aws_autoscaling_group.idp.name}: IdV: unexpected TrueID FaceMatch error
rate is above ${var.idv_unexpected_face_match_errors_threshold} occurrences over a period of 15 mins.

Dashboard: https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards/dashboard/${var.env_name}-idv-trueid-overview
%{if var.env_name == "prod"}
Notifying:%{for handle in var.slack_doc_auth_groups} @${handle}%{endfor}
%{endif}
EOM

  metric_name = "idv-unexpected-face-match-errors"
  namespace   = "${var.env_name}/idp-ialx"
  period      = 900
  statistic   = "Sum"

  alarm_actions       = local.moderate_priority_alarm_actions
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.idv_unexpected_face_match_errors_threshold
  evaluation_periods  = 1
}

resource "aws_cloudwatch_metric_alarm" "idp_high_tps" {
  for_each = var.idp_external_service_alarms_enabled == 1 ? {
    for service, config in var.external_service_alarms : service => config
    if config.tps_max != null
  } : {}

  alarm_name = join("-", [
    var.env_name, replace(each.key, "_", "-"), "tps-high"
  ])
  alarm_description = <<EOM
${each.key} transactions per second (TPS) in ${var.env_name} has reached at least
${each.value.tps_threshold_pct}% of the maximum allowed value for ${each.value.long_name}
(${each.value.tps_max} TPS / ${floor(format("%f", each.value.tps_max * 60))} TPM).

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
%{if var.env_name == "prod"}
Notifying:%{for handle in var.slack_oncall_groups} @${handle}%{endfor}
%{endif}

EOM

  # calculation: tps_threshold_pct of TPS x 60 seconds/min
  threshold = format(
    "%f", each.value.tps_max * format("%2.2f", each.value.tps_threshold_pct / 100) * 60
  )
  metric_name         = "faraday-response-time"
  namespace           = "${var.env_name}/idp-external-service"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  statistic           = "SampleCount"
  dimensions = {
    Service = each.key
  }
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions = var.env_name == "prod" ? (
  local.high_priority_alarm_actions) : local.moderate_priority_alarm_actions

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "idp_response_time_high" {
  for_each = var.idp_external_service_alarms_enabled == 1 ? {
    for service, config in var.external_service_alarms : service => config
    if config.latency_percentile != null
  } : {}

  alarm_name = join("-", [
    var.env_name, replace(each.key, "_", "-"), "response-time-high"
  ])
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  metric_name         = "faraday-response-time"
  namespace           = "${var.env_name}/idp-external-service"
  period              = "60"
  extended_statistic  = "p${each.value.latency_percentile}"
  dimensions = {
    Service = each.key
  }
  threshold                 = each.value.latency_threshold
  alarm_description         = <<EOM
${each.value.long_name} ${each.value.latency_percentile}th percentile response time
in ${var.env_name} has been greater than 10 seconds for 3 minutes

Runbook: https://handbook.login.gov/articles/vendor-outage-response-process.html
%{if var.env_name == "prod" && length(each.value.slack_oncall_handles) > 0}
Notifying: ${join(", ", each.value.slack_oncall_handles)}
%{endif}
EOM
  treat_missing_data        = "ignore"
  insufficient_data_actions = []
  alarm_actions             = local.doc_auth_alarm_actions

  lifecycle {
    create_before_destroy = true
  }
}

# https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-GPO-File-Upload-Failure
resource "aws_cloudwatch_metric_alarm" "gpo_confirmation_upload_failure" {
  alarm_name        = "${aws_autoscaling_group.idp.name}-gpo-confirmation-upload-failure"
  alarm_description = <<EOM
${aws_autoscaling_group.idp.name}: IdV: GPO confirmation upload failure

A GPO confirmation uplaod failure was detected.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-GPO-File-Upload-Failure
%{if var.env_name == "prod"}
Notifying:%{for handle in var.slack_proofing_groups} @${handle}%{endfor}
%{endif}
EOM

  metric_name = "idv-gpo-confirmation-upload-job-failures"
  namespace   = "${var.env_name}/idp-ialx"
  period      = 14400
  statistic   = "Sum"

  alarm_actions       = local.moderate_priority_alarm_actions
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
}
