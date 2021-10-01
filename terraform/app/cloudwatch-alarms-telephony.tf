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
  alarm_description         = "${var.env_name} IdP sent more than ${var.sms_send_rate_alert_threshold} SMS messages in 1 minute"
  treat_missing_data        = "breaching"
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
  alarm_description         = "${var.env_name} IdP sent more than ${var.voice_send_rate_alert_threshold} voice messages in 1 minute"
  treat_missing_data        = "breaching"
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
  alarm_description         = "${var.env_name} IdP experienced more than ${var.sms_error_rate_alert_threshold} SMS non-throttled message failures in 1 minute"
  treat_missing_data        = "breaching"
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
  alarm_description         = "${var.env_name} IdP experienced more than ${var.sms_error_rate_alert_threshold} SMS throttled message failures in 1 minute"
  treat_missing_data        = "breaching"
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
  alarm_description         = "${var.env_name} IdP experienced more than ${var.voice_error_rate_alert_threshold} voice non-throttled message failures in 1 minute"
  treat_missing_data        = "breaching"
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
  alarm_description         = "${var.env_name} IdP experienced more than ${var.voice_error_rate_alert_threshold} voice throttled message failures in 1 minute"
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

