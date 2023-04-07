resource "aws_cloudwatch_metric_alarm" "idp_worker_alive_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-Alive"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "6"
  datapoints_to_alarm       = "6"
  metric_name               = "perform-success"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60" # 6 minutes because heartbeat job is queued every 5 minutes, and queue is checked every 5 seconds
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = <<EOM
This alarm is executed when no worker jobs have run for 6 minutes

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_worker_alive_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPUSPSProofingWorker-Alive"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "3"
  datapoints_to_alarm       = "3"
  metric_name               = "usps-perform-success"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "1200" # 20 minute period, if this job doesn't run within an hour, we have an alarm state
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = <<EOM
This alarm is executed when USPS get proofing results job has not run for 60 minutes

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_worker_low_transaction_frequency_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPUSPSProofingWorker-LowTransactionFrequency"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "usps-perform-success"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "10800" # 3 hours
  statistic                 = "Sum"
  threshold                 = "3"
  alarm_description         = <<EOM
This alarm is executed when USPS get proofing results job has not run at least 3 times within 3 hours

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_worker_minutes_since_enrollment_established" {
  count = var.idp_worker_alarms_enabled

  metric_query {
    id          = "e1"
    label       = "Minutes Since USPS IPP Enrollment Established (Maximum)"
    expression  = "FIRST(SORT(METRICS(), MAX, DESC))"
    return_data = "true"
  }

  metric_query {
    id    = "m1"
    label = "(Exception raised) Max Minutes Since USPS IPP Enrollment Established"

    metric {
      metric_name = "usps-proofing-minutes-since-enrollment-established"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
      dimensions = {
        name = "GetUspsProofingResultsJob: Exception raised"
      }
    }
  }

  metric_query {
    id    = "m2"
    label = "(Enrollment status updated) Max Minutes Since USPS IPP Enrollment Established"

    metric {
      metric_name = "usps-proofing-minutes-since-enrollment-established"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
      dimensions = {
        name = "GetUspsProofingResultsJob: Enrollment status updated"
      }
    }
  }

  metric_query {
    id    = "m3"
    label = "(Enrollment incomplete) Max Minutes Since USPS IPP Enrollment Established"

    metric {
      metric_name = "usps-proofing-minutes-since-enrollment-established"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
      dimensions = {
        name = "GetUspsProofingResultsJob: Enrollment incomplete"
      }
    }
  }

  metric_query {
    id    = "m4"
    label = "(Unexpected response received) Max Minutes Since USPS IPP Enrollment Established"

    metric {
      metric_name = "usps-proofing-minutes-since-enrollment-established"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
      dimensions = {
        name = "GetUspsProofingResultsJob: Unexpected response received"
      }
    }
  }

  alarm_name                = "${var.env_name}-IDPUSPSProofingWorker-MinutesSinceEnrollmentEstablished"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  threshold                 = var.minutes_since_ipp_enrollment_established_alarm_threshold
  alarm_description         = <<EOM
This alarm is executed when USPS get proofing results job processes an enrollment that exceeds the expected timeframe for enrollment expiration

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_worker_minutes_since_last_status_check_completed" {
  count = var.idp_worker_alarms_enabled

  metric_query {
    id          = "e1"
    label       = "Minutes Since USPS IPP Enrollment Status Check Completed (Maximum)"
    expression  = "FIRST(SORT(METRICS(), MAX, DESC))"
    return_data = "true"
  }

  metric_query {
    id    = "m1"
    label = "Max Minutes Since USPS IPP Enrollment Status Check Completed"

    metric {
      metric_name = "usps-proofing-minutes-since-last-status-check-completed"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
    }
  }

  metric_query {
    id    = "m2"
    label = "Max Minutes Since USPS IPP Enrollment Established"

    metric {
      metric_name = "usps-proofing-minutes-without-status-check-completed-since-established"
      namespace   = "${var.env_name}/idp-in-person-proofing"
      period      = "3600" # 1 hour
      stat        = "Maximum"
    }
  }

  alarm_name                = "${var.env_name}-IDPUSPSProofingWorker-MinutesSinceEnrollmentStatusCheckCompleted"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  threshold                 = var.minutes_since_ipp_enrollment_status_check_completed_alarm_threshold
  alarm_description         = <<EOM
This alarm is executed when USPS get proofing results job has not successfully checked an enrollment's status for too long

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_worker_large_number_of_enrollments_set_to_expire" {
  count = var.idp_worker_alarms_enabled

  alarm_name          = "${var.env_name}-IDPUSPSProofingWorker-LargeNumberOfEnrollmentsSetToExpire"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "usps-proofing-minutes-since-enrollment-established"
  namespace           = "${var.env_name}/idp-in-person-proofing"
  period              = "21600" # 6 hours
  extended_statistic  = "p75"   # May want to revisit after IRS IPP launch
  dimensions = {
    name = "GetUspsProofingResultsJob: Enrollment incomplete"
  }
  threshold = var.enrollments_expiration_alarm_threshold

  alarm_description = <<EOM
25% of enrollments processed in a recent USPS get proofing results job are set to expire within about 7 days.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM

  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

# Send a slack notification if polling job takes >20 minutes to complete
resource "aws_cloudwatch_metric_alarm" "idp_usps_proofing_results_job_completed_long_duration" {
  count = var.idp_worker_alarms_enabled

  alarm_name          = "${var.env_name}-IDPUSPSProofingWorker-VeryLongJobCompletionTime"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "usps-proofing-job-completed-duration"
  namespace           = "${var.env_name}/idp-in-person-proofing"
  period              = "900" # Every 15 minutes
  statistic           = "Maximum"
  threshold           = var.long_usps_proofing_job_threshold

  alarm_description = <<EOM
USPS Proofing Job took more than 20 minutes to complete.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM

  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

# There should be no failures, so alert on any failure
resource "aws_cloudwatch_metric_alarm" "idp_worker_failure_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-Failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-failure"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = <<EOM
This alarm is executed when a worker job fails

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_queue_time_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-QueueTime"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "queue-time-milliseconds"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "10000" # Job queue is checked every 5 seconds
  alarm_description         = <<EOM
This alarm is executed when job queue time exceeds allowable limits

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_perform_time_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-PerformTime"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-time-milliseconds"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "50000"
  alarm_description         = <<EOM
This alarm is executed when job perform time exceeds allowable limits

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_threatmetrix_js_verification_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-ThreatMetrix-JSVerification"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "threatmetrix-js-invalid"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "3600"
  statistic                 = "Maximum"
  threshold                 = "0"
  alarm_description         = <<EOM
This alarm is executed when Javascript served by LexisNexis ThreatMetrix is not appropriately signed.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-ThreatMetrix-Javascript-verification
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}

