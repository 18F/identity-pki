# Rate overage alarms
resource "aws_cloudwatch_metric_alarm" "idp_sms_send_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-sms-send-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-sms-sent"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.sms_send_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP sent more than ${var.sms_send_rate_alert_threshold} SMS messages in 1 minute

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_voice_send_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-voice-send-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-voice-sent"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.voice_send_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP sent more than ${var.voice_send_rate_alert_threshold} voice messages in 1 minute which can indicate issues sending SMS

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

# Error rate alarms
resource "aws_cloudwatch_metric_alarm" "idp_sms_error_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-sms-error-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-sms-failed-other"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.sms_error_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP experienced more than ${var.sms_error_rate_alert_threshold} SMS non-throttled message failures in 1 minute

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_sms_throttled_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-sms-throttled-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-sms-failed-throttled"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.sms_error_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP experienced more than ${var.sms_error_rate_alert_threshold} SMS throttled message failures in 1 minute

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_voice_error_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-voice-error-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-voice-failed-other"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.voice_error_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP experienced more than ${var.voice_error_rate_alert_threshold} voice non-throttled message failures in 1 minute

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_voice_throttled_rate_high_alarm" {
  alarm_name                = "${var.env_name}-idp-voice-throttled-rate-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pinpoint-telephony-voice-failed-throttled"
  namespace                 = "${var.env_name}/idp-authentication"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = var.voice_error_rate_alert_threshold
  alarm_description         = <<EOM
${var.env_name} IdP experienced more than ${var.voice_error_rate_alert_threshold} voice throttled message failures in 1 minute

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_sms_resend_percentage_high_alarm" {
  count                     = var.sms_high_retry_percentage_threshold > 0 ? 1 : 0
  alarm_name                = "${var.env_name}-high_sms_resend_percentage_threshold"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  threshold                 = var.sms_high_retry_percentage_threshold
  alarm_description         = <<EOM
${var.env_name} IdP experienced more than ${var.sms_high_retry_percentage_threshold} percent of SMS retries in 5 minutes

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions


  metric_query {
    id          = "resend_percentage"
    expression  = "(resends / (resends + not_resends)) * 100"
    label       = "Resend Percentage"
    return_data = "true"
  }

  metric_query {
    id = "resends"

    metric {
      metric_name = "telephony-otp-sent-method-is-resend"
      namespace   = "${var.env_name}/idp-authentication"
      period      = 300
      stat        = "Sum"

      dimensions = {
        channel = "sms"
      }
    }
  }

  metric_query {
    id = "not_resends"

    metric {
      metric_name = "telephony-otp-sent-method-is-not-resend"
      namespace   = "${var.env_name}/idp-authentication"
      period      = 300
      stat        = "Sum"

      dimensions = {
        channel = "sms"
      }
    }
  }
}
