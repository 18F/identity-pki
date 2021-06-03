locals {
  auth_metric_namespace = "${var.env_name}/idp-authentication"
  ialx_metric_namespace = "${var.env_name}/idp-ialx"
  external_service_namespace = "${var.env_name}/idp-external-service"
  worker_namespace = "${var.env_name}/idp-worker"
  dashboard_name        = "${var.env_name}-idp-workload"
  external_service_dashboard_name = "${var.env_name}-idp-external-service"
}

variable "idp_events_auth_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = number
  }))
  default = {
    user_registration_complete = {
      name         = "user-registration-email-submitted"
      pattern      = "{ ($.name = \"User Registration: Email Submitted\") }"
      metric_value = 1
    },
    remembered_device_used_for_authentication = {
      name         = "remembered-device-used-for-authentication"
      pattern      = "{ ($.name = \"Remembered device used for authentication\") }"
      metric_value = 1
    },
    telephony_otp_sent = {
      name         = "telephony-otp-sent"
      pattern      = "{ ($.name = \"Telephony: OTP sent\") }"
      metric_value = 1
    },
    user_marked_authenticated = {
      name         = "user-marked-authenticated"
      pattern      = "{ ($.name = \"User marked authenticated\") }"
      metric_value = 1
    },
    user_registration_complete = {
      name         = "user-registration-complete"
      pattern      = "{ ($.name = \"User registration: complete\") }"
      metric_value = 1
    },
    multi_factor_authentication_setup_success = {
      name         = "multi-factor-authentication-setup-success"
      pattern      = "{ ($.name = \"Multi-Factor Authentication Setup\") && $.properties.event_properties.success is true }"
      metric_value = 1
    },
    login_failure_email_or_password = {
      name         = "login-failure-email-or-password"
      pattern      = "{ ($.name = \"Email and Password Authentication\") && $.properties.event_properties.success is false }"
      metric_value = 1
    },
    rate_limit_triggered = {
      name         = "rate-limit-triggered"
      pattern      = "{ ($.name = \"Rate Limit Triggered\") && ($.properties.event_properties.success is false) }"
      metric_value = 1
    },
    login_failure_mfa_sms = {
      name         = "login-failure-mfa-sms"
      pattern      = "{ ($.name = \"Multi-Factor Authentication\") && ($.properties.event_properties.success is false) && ($.properties.event_properties.multi_factor_auth_method = \"sms\") }"
      metric_value = 1
    },
    login_failure_mfa_personal_key = {
      name         = "login-failure-mfa-personal-key"
      pattern      = "{ ($.name = \"Multi-Factor Authentication\") && ($.properties.event_properties.success is false) && ($.properties.event_properties.multi_factor_auth_method = \"personal-key\") }"
      metric_value = 1
    },
    login_failure_mfa_piv_cac = {
      name         = "login-failure-mfa-piv_cac"
      pattern      = "{ ($.name = \"Multi-Factor Authentication\") && ($.properties.event_properties.success is false) && ($.properties.event_properties.multi_factor_auth_method = \"piv_cac\") }"
      metric_value = 1
    },
    login_failure_mfa_totp = {
      name         = "login-failure-mfa-totp"
      pattern      = "{ ($.name = \"Multi-Factor Authentication\") && ($.properties.event_properties.success is false) && ($.properties.event_properties.multi_factor_auth_method = \"totp\") }"
      metric_value = 1
    },
    login_failure_mfa_webauthn = {
      name         = "login-failure-mfa-webauthn"
      pattern      = "{ ($.name = \"Multi-Factor Authentication\") && ($.properties.event_properties.success is false) && ($.properties.event_properties.multi_factor_auth_method = \"webauthn\") }"
      metric_value = 1
    },
  }
}

variable "idp_events_ialx_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = number
  }))
  default = {
    idv_final_resolution_success = {
      name         = "idv-final-resolution-success"
      pattern      = "{ ($.name = \"IdV: final resolution\") && ($.properties.event_properties.success is true) }"
      metric_value = 1
    },
    doc_auth_submitted_success = {
      name         = "doc-auth-submitted-success"
      pattern      = "{ ($.name = \"IdV: final resolution\") && ($.properties.event_properties.success is true) }"
      metric_value = 1
    },
  }
}

variable "idp_kms_auth_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = number
  }))
  default = {
    kms_encrypt_session = {
      name         = "kms-encrypt-session"
      pattern      = "{ ($.kms.action = \"encrypt\" && $.kms.encryption_context.context = \"session-encryption\") }"
      metric_value = 1
    },
    kms_decrypt_session = {
      name         = "kms-decrypt-session"
      pattern      = "{ ($.kms.action = \"decrypt\" && $.kms.encryption_context.context = \"session-encryption\") }"
      metric_value = 1
    },
    kms_encrypt_password_digest = {
      name         = "kms-encrypt-password-digest"
      pattern      = "{ ($.kms.action = \"encrypt\" && $.kms.encryption_context.context = \"password-digest\") }"
      metric_value = 1
    },
    kms_decrypt_password_digest = {
      name         = "kms-decrypt-password-digest"
      pattern      = "{ ($.kms.action = \"decrypt\" && $.kms.encryption_context.context = \"password-digest\") }"
      metric_value = 1
    },
  }
}

variable "idp_telephony_auth_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = number
  }))
  default = {
    pinpoint_telephony_sms_sent = {
      name         = "pinpoint-telephony-sms-sent"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is true && $.channel = \"sms\" }"
      metric_value = 1
    },
    pinpoint_telephony_voice_sent = {
      name         = "pinpoint-telephony-voice-sent"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is true && $.channel = \"voice\" }"
      metric_value = 1
    },
    pinpoint_telephony_sms_failed_throttled = {
      name         = "pinpoint-telephony-sms-failed-throttled"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"sms\" && $.delivery_status = \"THROTTLED\" }"
      metric_value = 1
    },
    pinpoint_telephony_voice_failed_throttled = {
      name         = "pinpoint-telephony-voice-failed-throttled"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"voice\" && $.delivery_status = \"THROTTLED\" }"
      metric_value = 1
    },
    pinpoint_telephony_sms_failed_other = {
      name         = "pinpoint-telephony-sms-failed-other"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"sms\" && $.delivery_status != \"THROTTLED\" }"
      metric_value = 1
    },
    pinpoint_telephony_voice_failed_other = {
      name         = "pinpoint-telephony-voice-failed-other"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"voice\" && $.delivery_status != \"THROTTLED\" }"
      metric_value = 1
    },
  }
}

variable "idp_external_service_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = string
  }))
  default = {
    aws_kms_decrypt_response_time = {
      name         = "aws-kms-decrypt-response-time"
      pattern      = "[service=\"Aws::KMS::Client\", status, response_time_seconds, retries, operation=decrypt, error]"
      metric_value = "$response_time_seconds"
    },
    aws_kms_encrypt_response_time = {
      name         = "aws-kms-encrypt-response-time"
      pattern      = "[service=\"Aws::KMS::Client\", status, response_time_seconds, retries, operation=encrypt, error]"
      metric_value = "$response_time_seconds"
    },
    aws_pinpoint_send_messages_response_time = {
      name         = "aws-pinpoint-send-messages-response-time"
      pattern      = "[service=\"Aws::Pinpoint::Client\", status, response_time_seconds, retries, operation=send_messages, error]"
      metric_value = "$response_time_seconds"
    },
    aws_pinpoint_voice_send_voice_message_response_time = {
      name         = "aws-pinpoint-voice-send-voice-message-response-time"
      pattern      = "[service=\"Aws::PinpointSMSVoice::Client\", status, response_time_seconds, retries, operation=send_voice_message, error]"
      metric_value = "$response_time_seconds"
    },
    aws_pinpoint_phone_number_validate_response_time = {
      name         = "aws-pinpoint-phone-number-validate-response-time"
      pattern      = "[service=\"Aws::Pinpoint::Client\", status, response_time_seconds, retries, operation=phone_number_validate, error]"
      metric_value = "$response_time_seconds"
    },
    aws_ses_send_raw_email_response_time = {
      name         = "aws-ses-send-raw-email-response-time"
      pattern      = "[service=\"Aws::SES::Client\", status, response_time_seconds, retries, operation=send_raw_email, error]"
      metric_value = "$response_time_seconds"
    },
    aws_s3_put_object_response_time = {
      name         = "aws-s3-put-object-response-time"
      pattern      = "[service=\"Aws::S3::Client\", status, response_time_seconds, retries, operation=put_object, error]"
      metric_value = "$response_time_seconds"
    },
    aws_sts_assume_role_response_time = {
      name         = "aws-sts-assume-role-response-time"
      pattern      = "[service=\"Aws::STS::Client\", status, response_time_seconds, retries, operation=assume_role, error]"
      metric_value = "$response_time_seconds"
    },
    aws_lambda_invoke_response_time = {
      name         = "aws-lambda-invoke-response-time"
      pattern      = "[service=\"Aws::Lambda::Client\", status, response_time_seconds, retries, operation=invoke, error]"
      metric_value = "$response_time_seconds"
    },
  }
}

variable "idp_worker_filters" {
  type = map(object({
    name         = string
    pattern      = string
    metric_value = string
  }))
  default = {
    idp_worker_perform_time = {
      name         = "perform-time-milliseconds"
      pattern      = "{ $.name = \"perform.active_job\" && $.queue_name = \"*DelayedJob*\" }"
      metric_value = "$.duration_ms"
    },
    idp_worker_queue_time = {
      name         = "queue-time-milliseconds"
      pattern      = "{ $.name = \"perform_start.active_job\" && $.queue_name = \"*DelayedJob*\" }"
      metric_value = "$.queued_duration_ms"
    },
    idp_worker_perform_success = {
      name         = "perform-success"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message NOT EXISTS && $.queue_name = \"*DelayedJob*\" }"
      metric_value = 1
    },
    idp_worker_perform_failure = {
      name         = "perform-failure"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message = * && $.queue_name = \"*DelayedJob*\" }"
      metric_value = 1
    },
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_external_service" {
  for_each       = var.idp_external_service_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_production.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.external_service_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_events_auth" {
  for_each       = var.idp_events_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.auth_metric_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_events_ialx" {
  for_each       = var.idp_events_ialx_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.ialx_metric_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_kms_auth" {
  for_each       = var.idp_kms_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.kms_log.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.auth_metric_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_telephony_auth" {
  for_each       = var.idp_telephony_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_telephony.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.auth_metric_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_worker" {
  for_each       = var.idp_worker_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_workers.name
  metric_transformation {
    name      = each.value["name"]
    namespace = local.worker_namespace
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_alive_alarm" {
  alarm_name                = "${var.env_name} IDP Workers Alive Alert"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "6"
  datapoints_to_alarm       = "6"
  metric_name               = "perform-success"
  namespace                 = local.worker_namespace
  period                    = "60" # 6 minutes because heartbeat job is queued every 5 minutes, and queue is checked every 5 seconds
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This alarm is executed when no worker jobs have run for 6 minutes"
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

# There should be no failures, so alert on any failure
resource "aws_cloudwatch_metric_alarm" "idp_worker_failure_alarm" {
  alarm_name                = "${var.env_name} IDP Workers Failure Alert"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-failure"
  namespace                 = local.worker_namespace
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This alarm is executed when a worker job fails"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_queue_time_alarm" {
  alarm_name                = "${var.env_name} IDP Workers Queue Time Alert"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "queue-time-milliseconds"
  namespace                 = local.worker_namespace
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "10000" # Job queue is checked every 5 seconds
  alarm_description         = "This alarm is executed when job queue time exceeds allowable limits"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_perform_time_alarm" {
  alarm_name                = "${var.env_name} IDP Workers Perform Time Alert"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-time-milliseconds"
  namespace                 = local.worker_namespace
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "50000"
  alarm_description         = "This alarm is executed when job perform time exceeds allowable limits"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}


resource "aws_cloudwatch_dashboard" "idp_workload" {
  dashboard_name = local.dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "color": "#2ca02c", "label": "2XX" } ],
                    [ ".", "HTTPCode_Target_3XX_Count", ".", ".", { "label": "3XX" } ],
                    [ ".", "HTTPCode_Target_4XX_Count", ".", ".", { "color": "#1f77b4", "label": "4XX" } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "label": "5XX" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "us-west-2",
                "title": "${var.env_name} IdP - Backend Request Status by Code",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Requests (stacked)"
                    }
                },
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.idp.arn_suffix}", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "stat": "p90", "label": "p90" } ],
                    [ "...", { "label": "p99" } ],
                    [ "...", { "stat": "Maximum", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "title": "${var.env_name} IdP - Backend Request Response Time",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Latency (seconds)",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "visible": false,
                            "color": "#d68181",
                            "value": 1
                        }
                    ],
                    "vertical": [
                        {
                            "color": "#666",
                            "label": "CBP TTP Launch",
                            "value": "2017-10-01T16:00:00.000Z"
                        },
                        {
                            "color": "#666",
                            "label": "USAJobs Launch",
                            "value": "2018-02-25T15:00:00.000Z"
                        }
                    ]
                },
                "stat": "p99"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 38,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.pivcac[0].name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} PIVCAC - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 20,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.idp.name}", { "label": "IdP Instances" } ],
                    [ "...", "${aws_autoscaling_group.idpxtra.name}", { "label": "IdPXtra Instances" } ],
                    [ "AWS/RDS", ".", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Database" } ],
                    [ "AWS/ElastiCache", ".", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Cache (2)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "title": "${var.env_name} IdP - CPU Utilization",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "% Utilization (max)",
                        "showUnits": false
                    }
                },
                "stat": "Maximum",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "CPU Autoscaling Threshold",
                            "value": 40
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "(target_errs + elb_5xx) / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "Overall Error Rate", "id": "err_rate", "color": "#9467bd", "visible": false, "region": "us-west-2" } ],
                    [ { "expression": "elb_5xx / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "Load Balancer Frontend", "id": "elb_err_rate", "color": "#000", "region": "us-west-2" } ],
                    [ { "expression": "(target_errs / target_total) * 100", "label": "Webserver Backend", "id": "target_err_rate", "color": "#d62728", "period": 60, "stat": "Sum", "region": "us-west-2" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "id": "target_total", "label": "Backend RequestCount", "color": "#1f77b4", "yAxis": "right", "visible": false } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "id": "target_errs", "yAxis": "right", "visible": false, "color": "#ffbb78" } ],
                    [ ".", "HTTPCode_ELB_3XX_Count", ".", ".", { "id": "elb_3xx", "yAxis": "right", "visible": false, "color": "#c49c94" } ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "id": "elb_4xx", "yAxis": "right", "visible": false, "color": "#bcbd22" } ],
                    [ ".", "HTTPCode_ELB_5XX_Count", ".", ".", { "id": "elb_5xx", "yAxis": "right", "visible": false, "color": "#c5b0d5" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "yAxis": {
                    "left": {
                        "label": "Error %",
                        "showUnits": false,
                        "min": 0
                    }
                },
                "title": "${var.env_name} IdP - HTTP Error Rate",
                "period": 60,
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#ffbb80",
                            "label": "Warning",
                            "value": 1
                        },
                        {
                            "color": "#d68181",
                            "label": "Alarm",
                            "value": 5
                        }
                    ]
                },
                "legend": {
                    "position": "bottom"
                },
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 26,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Database" } ],
                    [ "AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Cache (2)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "title": "${var.env_name} IdP - Datastore Connections",
                "stat": "Maximum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "label": "Connections (max)",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 20,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Write" } ],
                    [ ".", "ReadIOPS", ".", ".", { "label": "Read" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "${var.env_name} IdP - Database IOPS",
                "region": "us-west-2",
                "period": 60,
                "stat": "Maximum",
                "yAxis": {
                    "left": {
                        "label": "IOPS (max)",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Provisioned IOPS",
                            "value": 3500,
                            "fill": "above"
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SES", "Send", { "label": "Global SES Send [sum: $${SUM}]" } ],
                    [ ".", "Delivery", { "label": "Global SES Delivery [sum: $${SUM}]" } ],
                    [ ".", "Bounce", { "label": "Global SES Bounce [sum: $${SUM}]" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Sum",
                "period": 60,
                "title": "IdP - Combined Account Email",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 2,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-authentication", "user-marked-authenticated", { "label": "authenticated [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "user-registration-complete", { "label": "registration-complete [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "remembered-device-used-for-authentication", { "label": "remembered-device [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "rate-limit-triggered", { "label": "rate-limited [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-email-or-password", { "label": "fail-email-pass [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-mfa-sms", { "label": "fail-mfa-sms [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-mfa-totp", { "label": "fail-mfa-totp [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-mfa-voice", { "label": "fail-mfa-voice [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-mfa-piv_cac", { "label": "fail-mfa-pivcac [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-mfa-personal-key", { "label": "fail-mfa-personal-key [sum:$${SUM}, max:$${MAX}]" } ],
                    [ "${var.env_name}/idp-ialx", "idv-final-resolution-success", { "label": "idv-final-resolution-success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "doc-auth-submitted-success", { "label": "doc-auth-submitted-success [sum:$${SUM}, max:$${MAX}]" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} IdP - Authentication Events",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 32,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Usage", "CallCount", "Type", "API", "Resource", "CryptographicOperationsSymmetric", "Service", "KMS", "Class", "None", { "visible": false } ],
                    [ "...", "DescribeCustomKeyStores", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListAliases", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "GetKeyRotationStatus", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "DescribeKey", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListKeys", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "GetKeyPolicy", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListResourceTags", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "CreateGrant", ".", ".", ".", ".", { "visible": false } ],
                    [ "${var.env_name}/idp-authentication", "kms-encrypt-session", { "label": "kms-encrypt-session" } ],
                    [ ".", "kms-decrypt-session", { "label": "kms-decrypt-session" } ],
                    [ ".", "kms-encrypt-password-digest", { "label": "kms-encrypt-password-digest" } ],
                    [ ".", "kms-decrypt-password-digest", { "label": "kms-decrypt-password-digest" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "us-west-2",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} IdP - KMS Symmetric Encryption Events",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 2,
            "properties": {
                "markdown": "\n# ${var.env_name} Workload\n\nNote that \"Events\" values are displayed in units of __events / interval__ where __interval__ changes as you zoom out.  Use __Actions -> Period__ and set to 1 minute to see consistent units.\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 26,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.idp.name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} IdP - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 2,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-authentication", "pinpoint-telephony-sms-sent", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-sent" } ],
                    [ ".", "pinpoint-telephony-sms-failed-throttled", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-failed-throttled" } ],
                    [ ".", "pinpoint-telephony-sms-failed-other", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-failed-other" } ],
                    [ ".", "pinpoint-telephony-voice-sent", { "label": "[sum: $${SUM}] pinpoint-telephony-voice-sent" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} - Telephony Detail",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 32,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.idpxtra.name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} IdPXtra - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 38,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} - Proxy Requests",
                "metrics": [
                    [ "LogMetrics/squid", "${var.env_name}/DeniedRequests" ],
                    [ ".", "${var.env_name}/TotalRequests" ]
                ],
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Requests"
                    }
                }
            }
        }
    ]
}
EOF
}

resource "aws_cloudwatch_dashboard" "idp_external_service" {
  dashboard_name = local.external_service_dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 12,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "stat": "p99",
                "title": "AWS 99th Percentile Response Times",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Seconds"
                    },
                    "right": {
                        "label": "",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 12,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt", "yAxis": "right" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt", "yAxis": "right" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 60,
                "stat": "SampleCount",
                "title": "AWS Requests",
                "setPeriodToTimeRange": true,
                "yAxis": {
                    "left": {
                        "showUnits": true
                    }
                },
                "legend": {
                    "position": "bottom"
                }
            }
        }
    ]
}
EOF
}

variable "idp_ial2_sp_dashboards" {
  type = map(map(object({
    name         = string
    issuer       = string
    protocol     = string
  })))

  default = {
    prod = {
      ssa_dashboard = {
        name         = "IAL2-Monitoring-SSA"
        issuer       = "urn:gov:gsa:SAML:2.0.profiles:sp:sso:SSA:mySSAsp"
        protocol     = "SAML"
      }
   },
    mhenke = {
      oidc_sinatra_dashboard = {
        name         = "IAL2-Monitoring-OIDC-Sinatra"
        issuer       = "urn:gov:gsa:openidconnect:sp:sinatra"
        protocol     = "OIDC"
      }
    },
    dev = {
      oidc_sinatra_dashboard = {
        name         = "IAL2-Monitoring-OIDC-Sinatra"
        issuer       = "urn:gov:gsa:openidconnect:sp:sinatra"
        protocol     = "OIDC"
      },
      saml_sinatra_dashboard = {
        name         = "IAL2-Monitoring-SAML-Sinatra"
        issuer       = "urn:gov:gsa:SAML:2.0.profiles:sp:sso:rails-dev"
        protocol     = "SAML"
      }
    },
    int = {
      oidc_sinatra_dashboard = {
        name         = "IAL2-Monitoring-OIDC-Sinatra"
        issuer       = "urn:gov:gsa:openidconnect:sp:sinatra"
        protocol     = "OIDC"
      },
      saml_sinatra_dashboard = {
        name         = "IAL2-Monitoring-SAML-Sinatra"
        issuer       = "urn:gov:gsa:SAML:2.0.profiles:sp:sso:rails-int"
        protocol     = "SAML"
      }
    }
  }
}

resource "aws_cloudwatch_dashboard" "idp_ial2_sp_dashboards" {
  for_each       = lookup(var.idp_ial2_sp_dashboards, var.env_name, {})

  dashboard_name = "${var.env_name}-${each.value["name"]}"

  dashboard_body = jsonencode({
    "widgets": [
      each.value["issuer"] == "SAML" ? {
            "height": 9,
            "width": 12,
            "y": 26,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'SAML Auth'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "title": "SAML Auths",
                "view": "timeSeries"
            }
        } : {
            "height": 9,
            "width": 12,
            "y": 26,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'OpenID Connect: authorization request'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "title": "OIDC Requests",
                "view": "timeSeries"
            }
        },
        {
            "height": 9,
            "width": 12,
            "y": 26,
            "x": 12,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'SP redirect initiated'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "title": "Redirects back to SP",
                "view": "timeSeries"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "\n# Funnels:\n"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 25,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "\n# Request counts\n"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 41,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "\n# Errors:\n"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 42,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter (\n    (name = 'IdV: doc auth image upload vendor submitted' and !properties.event_properties.success) or\n    (name = 'Doc Auth optional submitted' and !properties.event_properties.success) or\n    (name = 'IdV: phone confirmation vendor' and !properties.event_properties.success)\n)\n| parse @message \"IdV: doc auth image upload vendor submitted\" as document_capture_error\n| parse @message \"Doc Auth optional submitted\" as verify_error\n| parse @message \"IdV: phone confirmation vendor\" as phone_error\n| stats \n    count(document_capture_error) as document_capture_error_count,\n    count(verify_error)           as verify_error_count,\n    count(phone_error)            as phone_error_count\n    by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "title": "Unsuccessful proofing vendor submissions",
                "view": "timeSeries"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 35,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter name = 'Doc Auth visited'\n| stats count_distinct(visit_id) as session_count by properties.service_provider",
                "region": "us-west-2",
                "stacked": false,
                "view": "bar",
                "title": "Proofing attempt count by service provider"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 35,
            "x": 12,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter name = 'IdV: final resolution'\n| stats count_distinct(visit_id) as session_count by properties.service_provider",
                "region": "us-west-2",
                "stacked": false,
                "view": "bar",
                "title": "Proofing success by service provider"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 7,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof']\n| stats count_distinct(visit_id) as session_count by name\n| sort session_count desc, name asc",
                "region": "us-west-2",
                "stacked": false,
                "title": "Proofing Funnel - Sessions",
                "view": "bar"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 1,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof']\n| stats count_distinct(properties.user_id) as user_count by name\n| sort user_count desc, name asc",
                "region": "us-west-2",
                "stacked": false,
                "title": "Proofing Funnel - Unique Users",
                "view": "bar"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 13,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'Return to SP: Failed to proof'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "view": "timeSeries",
                "title": "Failed to Proof, returned to service provider"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 48,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message, properties.event_properties.step, properties.event_properties.errors.results.0 as error_message\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter !properties.event_properties.success\n| stats count(*) as error_count by error_message\n| sort error_count desc\n",
                "region": "us-west-2",
                "stacked": false,
                "title": "Primary (First) Error from Doc Auth Vendor",
                "view": "bar"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 54,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message, properties.event_properties.exception as exception\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter !properties.event_properties.success and !isblank(properties.event_properties.exception)\n| stats count(*) as exception_count, count_distinct(properties.user_id) as unique_users by exception\n| sort exception_count desc",
                "region": "us-west-2",
                "stacked": false,
                "title": "Acuant Exceptions",
                "view": "bar"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 19,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, properties.event_properties.source as image_capture_type, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'Frontend: IdV: front image added' OR name = 'Frontend: IdV: back image added'\n| parse image_capture_type \"acuant\" as acuant\n| parse image_capture_type \"upload\" as upload\n| stats count(acuant) as acuant_count, count(upload) as upload_count, acuant_count + upload_count as total_count by bin(10min)\n| sort @timestamp desc",
                "region": "us-west-2",
                "stacked": false,
                "view": "timeSeries",
                "title": "Doc Auth image capture type"
            }
        }
    ]
  })
}
