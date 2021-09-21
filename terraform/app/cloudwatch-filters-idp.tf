locals {
  idp_events_auth_filters = {
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

  idp_events_ialx_filters = {
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

  idp_kms_auth_filters = {
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

  idp_telephony_auth_filters = {
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


  idp_external_service_filters = {
    aws_kms_decrypt_response_time = {
      name         = "aws-kms-decrypt-response-time"
      pattern      = "[service=\"Aws::KMS::Client\", status, response_time_seconds, retries, operation=decrypt, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_kms_encrypt_response_time = {
      name         = "aws-kms-encrypt-response-time"
      pattern      = "[service=\"Aws::KMS::Client\", status, response_time_seconds, retries, operation=encrypt, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_pinpoint_send_messages_response_time = {
      name         = "aws-pinpoint-send-messages-response-time"
      pattern      = "[service=\"Aws::Pinpoint::Client\", status, response_time_seconds, retries, operation=send_messages, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_pinpoint_voice_send_voice_message_response_time = {
      name         = "aws-pinpoint-voice-send-voice-message-response-time"
      pattern      = "[service=\"Aws::PinpointSMSVoice::Client\", status, response_time_seconds, retries, operation=send_voice_message, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_pinpoint_phone_number_validate_response_time = {
      name         = "aws-pinpoint-phone-number-validate-response-time"
      pattern      = "[service=\"Aws::Pinpoint::Client\", status, response_time_seconds, retries, operation=phone_number_validate, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_ses_send_raw_email_response_time = {
      name         = "aws-ses-send-raw-email-response-time"
      pattern      = "[service=\"Aws::SES::Client\", status, response_time_seconds, retries, operation=send_raw_email, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_s3_put_object_response_time = {
      name         = "aws-s3-put-object-response-time"
      pattern      = "[service=\"Aws::S3::Client\", status, response_time_seconds, retries, operation=put_object, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_sts_assume_role_response_time = {
      name         = "aws-sts-assume-role-response-time"
      pattern      = "[service=\"Aws::STS::Client\", status, response_time_seconds, retries, operation=assume_role, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    aws_lambda_invoke_response_time = {
      name         = "aws-lambda-invoke-response-time"
      pattern      = "[service=\"Aws::Lambda::Client\", status, response_time_seconds, retries, operation=invoke, error]"
      metric_value = "$response_time_seconds"
      dimensions   = {}
    },
    faraday_response_time = {
      name         = "faraday-response-time"
      pattern      = "{ $.name = \"request_metric.faraday\" }"
      metric_value = "$.duration_seconds"
      dimensions = {
        Service = "$.service"
      },
    },
  }

  idp_worker_filters = {
    idp_worker_perform_time = {
      name         = "perform-time-milliseconds"
      pattern      = "{ $.name = \"perform.active_job\" && $.queue_name = \"*GoodJob*\" && $.queue_name != \"*long_running*\" }"
      metric_value = "$.duration_ms"
    },
    idp_worker_queue_time = {
      name         = "queue-time-milliseconds"
      pattern      = "{ $.name = \"perform_start.active_job\" && $.queue_name = \"*GoodJob*\" && $.queue_name != \"*long_running*\" }"
      metric_value = "$.queued_duration_ms"
    },
    idp_worker_perform_success = {
      name         = "perform-success"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message NOT EXISTS && $.queue_name = \"*GoodJob*\" }"
      metric_value = 1
    },
    idp_worker_perform_failure = {
      name         = "perform-failure"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message = * && $.queue_name = \"*GoodJob*\" }"
      metric_value = 1
    },
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_external_service" {
  for_each       = local.idp_external_service_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_production.name
  metric_transformation {
    name       = each.value["name"]
    namespace  = "${var.env_name}/idp-external-service"
    value      = each.value["metric_value"]
    dimensions = each.value["dimensions"]
  }
}
resource "aws_cloudwatch_log_metric_filter" "idp_events_auth" {
  for_each       = local.idp_events_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/idp-authentication"
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_events_ialx" {
  for_each       = local.idp_events_ialx_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/idp-ialx"
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_kms_auth" {
  for_each       = local.idp_kms_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.kms_log.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/idp-authentication"
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_telephony_auth" {
  for_each       = local.idp_telephony_auth_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_telephony.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/idp-authentication"
    value     = each.value["metric_value"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_worker" {
  for_each       = local.idp_worker_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_workers.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/idp-worker"
    value     = each.value["metric_value"]
  }
}
