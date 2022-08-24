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

locals {
  gitlab_user_sync_metric_namespace = "Gitlab/${var.env_name}"
  gitlab_user_sync_metric_name      = "UserSyncSuccess"
  gitlab_user_sync_dashboard_name   = "${var.env_name}-Gitlab-User-Sync"
  secrets_bucket                    = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
}

# These values can be shared via S3 with Chef, which creates the cronjob.
resource "aws_s3_object" "gitlab_user_sync_metric_namespace" {
  bucket  = local.secrets_bucket
  key     = "${var.env_name}/gitlab_user_sync_metric_namespace"
  content = local.gitlab_user_sync_metric_namespace
}
resource "aws_s3_object" "gitlab_user_sync_metric_name" {
  bucket  = local.secrets_bucket
  key     = "${var.env_name}/gitlab_user_sync_metric_name"
  content = local.gitlab_user_sync_metric_name
}

resource "aws_cloudwatch_metric_alarm" "gitlab_user_sync_failures" {
  alarm_name                = "${var.env_name} user sync unsuccessful"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = local.gitlab_user_sync_metric_name
  namespace                 = local.gitlab_user_sync_metric_namespace
  period                    = 3600 * 3
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This Alarm is executed if the user sync script has NOT completed successfully in the last 3 hours. Investigate the logs at https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${local.gitlab_user_sync_dashboard_name}"
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions = [
    "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:slack-events",
  ]
}

# Not used by the alert dashboard, but helpful if we're looking at CloudWatch Log Insights.
resource "aws_cloudwatch_query_definition" "gitlab_user_sync" {
  name            = "${var.env_name}/user-sync"
  log_group_names = ["${var.env_name}_/var/log/syslog"]
  query_string    = <<EOF
fields @message
| filter @message like /users\/sync\.sh/
| sort @timestamp asc
EOF
}

resource "aws_cloudwatch_dashboard" "gitlab_user_sync" {
  dashboard_name = local.gitlab_user_sync_dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 15,
            "width": 24,
            "y": 3,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${var.env_name}_/var/log/syslog' | SOURCE 'CloudTrail/DefaultLogGroup' | fields @message\n| filter @message like /users.sync.sh/\n| sort by @timestamp asc",
                "region": "${var.region}",
                "stacked": false,
                "title": "Logs",
                "view": "table"
            }
        },
        {
            "height": 3,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "sparkline": true,
                "view": "singleValue",
                "metrics": [
                    [ "Gitlab/${var.env_name}", "UserSyncSuccess" ]
                ],
                "region": "${var.region}"
            }
        }
    ]
}
EOF
}
