resource "aws_cloudwatch_log_group" "dns_query_log" {
  name              = "${var.env_name}/dns/query"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "${var.env_name}_flow_log_group"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "all_gitlab_logs" {
  name              = "${var.env_name}_all_gitlab_logs"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_access_log" {
  name              = "${var.env_name}_gitlab_access_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_error_log" {
  name              = "${var.env_name}_gitlab_error_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_audit_log" {
  name              = "${var.env_name}_gitlab_audit_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
resource "aws_cloudwatch_log_group" "gitlab_application_log" {
  name              = "${var.env_name}_gitlab_application_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
resource "aws_cloudwatch_log_group" "gitlab_backup_log" {
  name              = "${var.env_name}_gitlab_backup_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_messages_log" {
  name              = "${var.env_name}_/var/log/messages"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_metric_filter" "gitlab_backup_failures" {
  name           = "gitlab_${var.env_name}_backup_failures"
  pattern        = "gitlab backup FAILED"
  log_group_name = aws_cloudwatch_log_group.gitlab_messages_log.name

  metric_transformation {
    name      = "BackupFailure"
    namespace = "Gitlab/${var.env_name}"
    value     = "1"
  }
}

# This alert is set pretty long because we want to see it during the
# day.  If you fix the problem and run the backup script by hand,
# the alarm will not clear until 12h goes by.
resource "aws_cloudwatch_metric_alarm" "gitlab_backup_failures" {
  alarm_name                = "gitlab_${var.env_name}_backup_failures"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BackupFailure"
  namespace                 = "Gitlab/${var.env_name}"
  period                    = "43200"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Gitlab ${var.env_name} had backups fail!"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = [var.slack_events_sns_hook_arn]
}
