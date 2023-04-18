# SNS topics used for alarms are expected to be present at the account level
data "aws_sns_topic" "alert_critical" {
  name = var.sns_topic_alert_critical
}

data "aws_sns_topic" "alert_warning" {
  name = var.sns_topic_alert_warning
}

resource "aws_sns_topic" "autoscaling_events" {
  name              = "autoscaling-launch-events"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic" "rds_snapshot_events" {
  name = "rds-snapshot-events"
}

resource "aws_db_event_subscription" "idp" {
  name      = "snapshot-create-events"
  sns_topic = aws_sns_topic.rds_snapshot_events.arn

  source_type = "db-snapshot"

  event_categories = [
    "creation",
  ]
}
