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

resource "aws_cloudwatch_event_target" "opsgenie_root_user_accessed" {
  count     = var.opsgenie_key_ready ? 1 : 0
  provider  = aws.use1
  rule      = aws_cloudwatch_event_rule.root_user_accessed.name
  target_id = "SendToOpsgenie"
  arn       = module.opsgenie_sns[0].use1_sns_topic_arn
}