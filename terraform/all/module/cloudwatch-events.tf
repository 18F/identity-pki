resource "aws_cloudwatch_event_rule" "root_user_accessed" {
  provider      = aws.use1
  name          = "account-root-user-accessed"
  description   = "AWS Root account accessed"
  event_pattern = <<EOF
{
    "detail-type": [
        "AWS API Call via CloudTrail",
        "AWS Console Sign In via CloudTrail"
    ],
    "detail": {
        "userIdentity": {
            "type": [
                "Root"
            ]
        }
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "slack_root_user_accessed" {
  provider  = aws.use1
  rule      = aws_cloudwatch_event_rule.root_user_accessed.name
  target_id = "SendToSlack"
  arn       = aws_sns_topic.slack_use1["soc"].arn
}

resource "aws_cloudwatch_event_target" "page_root_user_accessed" {
  provider  = aws.use1
  rule      = aws_cloudwatch_event_rule.root_user_accessed.name
  target_id = "SendToOpsgenie"
  arn       = module.splunk_oncall_sns_use1.sns_topic_arns["login-platform"]
}

# AWS Health Aware (Personal Health Dashboard notification)
# Every region we have resources in needs its own subscription
resource "aws_cloudwatch_event_rule" "phd_us_east_1" {
  provider      = aws.use1
  name          = "PHD-Events-US-East-1"
  description   = "Personal Health Dashboard events"
  event_pattern = <<EOF
{
  "source": ["aws.health"],
  "detail-type": ["AWS Health Event"],
  "detail": {
    "service": ${jsonencode(var.phd_alerted_services)}
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "phd_us_west_2" {
  provider      = aws.usw2
  name          = "PHD-Events-US-West-2"
  description   = "Personal Health Dashboard events"
  event_pattern = <<EOF
{
  "source": ["aws.health"],
  "detail-type": ["AWS Health Event"],
  "detail": {
    "service": ${jsonencode(var.phd_alerted_services)}
  }
}
EOF
}

# Collect PHD alerts in US-East-1
resource "aws_cloudwatch_event_target" "phd_alert_us_east_1" {
  provider  = aws.use1
  rule      = aws_cloudwatch_event_rule.phd_us_east_1.name
  target_id = "SendToEventsSlack"
  # Personal Health Dashboard alerts are main event channel worthy for any account
  arn = aws_sns_topic.slack_use1["events"].arn
}

resource "aws_cloudwatch_event_target" "phd_alert_us_west_2" {
  provider  = aws.usw2
  rule      = aws_cloudwatch_event_rule.phd_us_west_2.name
  target_id = "SendToEventsSlack"
  # Personal Health Dashboard alerts are main event channel worthy for any account
  arn = aws_sns_topic.slack_usw2["events"].arn
}
