locals {
  idp_events_auth_filters = {
    user_registration_complete = {
      name         = "user-registration-email-submitted"
      pattern      = "{ ($.name = \"User Registration: Email Submitted\") }"
      metric_value = 1
      dimensions   = {}
    },
    remembered_device_used_for_authentication = {
      name         = "remembered-device-used-for-authentication"
      pattern      = "{ ($.name = \"Remembered device used for authentication\") }"
      metric_value = 1
      dimensions   = {}
    },
    telephony_otp_sent = {
      name         = "telephony-otp-sent"
      pattern      = "{ ($.name = \"Telephony: OTP sent\") }"
      metric_value = 1
      dimensions   = {}
    },
    telephony_otp_sent_method_is_resend = {
      name         = "telephony-otp-sent-method-is-resend"
      pattern      = "{ ($.name = \"Telephony: OTP sent\") && $.properties.event_properties.success is true && $.properties.event_properties.resend is true }"
      metric_value = 1
      dimensions = {
        channel = "$.properties.event_properties.otp_delivery_preference",
      }
    },
    telephony_otp_sent_method_not_resend = {
      name         = "telephony-otp-sent-method-is-not-resend"
      pattern      = "{ ($.name = \"Telephony: OTP sent\") && $.properties.event_properties.success is true && ($.properties.event_properties.resend is false || $.properties.event_properties.resend is null) }"
      metric_value = 1
      dimensions = {
        channel = "$.properties.event_properties.otp_delivery_preference",
      }
    },
    user_marked_authenticated = {
      name         = "user-marked-authenticated"
      pattern      = "{ ($.name = \"User marked authenticated\") }"
      metric_value = 1
      dimensions   = {}
    },
    user_registration_complete = {
      name         = "user-registration-complete"
      pattern      = "{ ($.name = \"User Registration: User Fully Registered\") }"
      metric_value = 1
      dimensions   = {}
    },
    multi_factor_authentication_setup_success = {
      name         = "multi-factor-authentication-setup-success"
      pattern      = "{ ($.name = \"Multi-Factor Authentication Setup\") && $.properties.event_properties.success is true }"
      metric_value = 1
      dimensions   = {}
    },
    login_failure_email_or_password = {
      name         = "login-failure-email-or-password"
      pattern      = "{ ($.name = \"Email and Password Authentication\") && $.properties.event_properties.success is false }"
      metric_value = 1
      dimensions   = {}
    },
    rate_limit_triggered = {
      name         = "rate-limit-triggered"
      pattern      = "{ ($.name = \"Rate Limit Triggered\") && ($.properties.event_properties.success is false) }"
      metric_value = 1
      dimensions   = {}
    },
    # Defining both multidimension and single dimension sp-redirect metrics to
    # avoid the limitation on using SEARCH in alarms.
    # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html#metric-math-syntax
    sp_redirect_initiated = {
      name         = "sp-redirect-initiated"
      pattern      = "{ ($.name = \"SP redirect initiated\") }"
      metric_value = 1
      dimensions = {
        service_provider = "$.properties.service_provider",
      }
    },
    sp_redirect_initiated_all = {
      name         = "sp-redirect-initiated-all"
      pattern      = "{ ($.name = \"SP redirect initiated\") }"
      metric_value = 1
      dimensions   = {}
    }
    login_multi_factor_authentication_success = {
      name         = "login-mfa-success"
      pattern      = "{ $.name = \"Multi-Factor Authentication\" && $.properties.event_properties.success is true }"
      metric_value = 1
      dimensions = {
        multi_factor_auth_method = "$.properties.event_properties.multi_factor_auth_method"
      },
    },

    login_multi_factor_authentication_failure = {
      name         = "login-mfa-failure"
      pattern      = "{ $.name = \"Multi-Factor Authentication\" && $.properties.event_properties.success is false }"
      metric_value = 1
      dimensions = {
        multi_factor_auth_method = "$.properties.event_properties.multi_factor_auth_method"
      },
    },

    # Server to server check after SP redirect
    sp_oidc_token_success = {
      name         = "sp-oidc-token-success"
      pattern      = "{ $.name = \"OpenID Connect: token\" && $.properties.event_properties.success is true }"
      metric_value = 1
      dimensions = {
        service_provider = "$.properties.event_properties.client_id",
      }
    },
  }

  idp_events_ialx_filters = {
    idv_review_complete_success = {
      name         = "idv-review-complete-success"
      pattern      = "{ ($.name = \"IdV: review complete\") }"
      metric_value = 1
    },
    # Per-SP to allow a breakdown of IdV
    sp_idv_final_resolution_success = {
      name         = "idv-final-resolution-success"
      pattern      = "{ $.name = \"IdV: final resolution\" && $.properties.event_properties.success is true }"
      metric_value = 1
      dimensions = {
        service_provider = "$.properties.service_provider",
      }
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
      # PERMANENT_FAILURE occurs when a person's phone number is opted out of SMS
      name         = "pinpoint-telephony-sms-failed-other"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"sms\" && $.delivery_status != \"THROTTLED\" && $.delivery_status != \"PERMANENT_FAILURE\"}"
      metric_value = 1
    },
    pinpoint_telephony_voice_failed_other = {
      name         = "pinpoint-telephony-voice-failed-other"
      pattern      = "{ $.adapter = \"pinpoint\" && $.success is false && $.channel = \"voice\" && $.delivery_status != \"THROTTLED\" }"
      metric_value = 1
    },
  }

  in_person_proofing_filters = {
    login_in_person_proofing_enrollment_failure = {
      name         = "login-in-person-proofing-failure"
      pattern      = "{ ($.name = \"USPS IPPaaS enrollment failed\") }"
      metric_value = 1
      dimensions   = {}
    },
    idp_usps_proofing_results_perform_exception = {
      name         = "usps-proofing-unexpected-exception"
      pattern      = "{ $.name = \"GetUspsProofingResultsJob: Exception raised\" }"
      metric_value = 1
      dimensions   = {}
    },
    idp_usps_proofing_results_minutes_since_enrollment_established = {
      name         = "usps-proofing-minutes-since-enrollment-established"
      pattern      = "{ ($.name = \"GetUspsProofingResultsJob:*\") && ($.properties.event_properties.enrollment_id > 0) && ($.properties.event_properties.minutes_since_established > -1) }"
      metric_value = "$.properties.event_properties.minutes_since_established"
      dimensions = {
        name = "$.name"
      }
    }
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
      pattern      = "{ $.name = \"perform_start.active_job\" && $.queue_name = \"*GoodJob*\" && $.queue_name != \"*long_running*\" && $.queue_name != \"*intentionally_delayed*\" }"
      metric_value = "$.queued_duration_ms"
    },
    idp_worker_perform_success = {
      name         = "perform-success"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message NOT EXISTS && $.queue_name = \"*GoodJob*\" }"
      metric_value = 1
    },
    idp_usps_proofing_results_worker_perform_success = {
      name         = "usps-perform-success"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message NOT EXISTS && $.queue_name = \"*GoodJob*\" && $.job_class = \"GetUspsProofingResultsJob\" }"
      metric_value = 1
    },
    idp_worker_perform_failure = {
      name         = "perform-failure"
      pattern      = "{ $.name = \"perform.active_job\" && $.exception_message = * && $.queue_name = \"*GoodJob*\" && $.queue_name != \"*long_running*\" }"
      metric_value = 1
    },
    threatmetrix_js_invalid = {
      name         = "threatmetrix-js-invalid"
      pattern      = "{ ($.name = \"ThreatMetrixJsVerification\") && ($.valid IS FALSE) }"
      metric_value = 1
      dimensions   = {}
    },
  }

  idp_attempts_api_filters = {
    attempts_api_events_auth_failure = {
      name         = "attempts-api-events-auth-failure"
      pattern      = "{ ($.name = \"IRS Attempt API: Events submitted\" ) && ($.properties.event_properties.authenticated is false) }"
      metric_value = 1
    },
    attempts_api_events_success = {
      name         = "attempts-api-events-success"
      pattern      = "{ ($.name = \"IRS Attempt API: Events submitted\" ) && ($.properties.event_properties.success is true) }"
      metric_value = 1
    }
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
    name       = each.value["name"]
    namespace  = "${var.env_name}/idp-authentication"
    value      = each.value["metric_value"]
    dimensions = each.value["dimensions"]
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_events_in_person_proofing" {
  for_each       = local.in_person_proofing_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name       = each.value["name"]
    namespace  = "${var.env_name}/idp-in-person-proofing"
    value      = each.value["metric_value"]
    dimensions = each.value["dimensions"]
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

resource "aws_cloudwatch_log_metric_filter" "pii_spill_detector" {
  name           = "pii-spill-detector"
  pattern        = join(" ", [for v in var.idp_pii_spill_patterns : "?\"${v}\""])
  log_group_name = aws_cloudwatch_log_group.idp_events.name

  metric_transformation {
    name          = "PII_Spill_Event"
    namespace     = "${var.env_name}/SpillDetectorMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "attempts_api_events" {
  for_each       = local.idp_attempts_api_filters
  name           = each.value["name"]
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.idp_events.name
  metric_transformation {
    name      = each.value["name"]
    namespace = "${var.env_name}/attempts-api-events"
    value     = each.value["metric_value"]
  }
}
