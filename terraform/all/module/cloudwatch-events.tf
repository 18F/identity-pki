resource "aws_cloudwatch_event_rule" "root_user_accessed" {
    provider = aws.use1
    name = "account-root-user-accessed"
    description = "AWS Root account accessed"
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
    provider = aws.use1
    rule = aws_cloudwatch_event_rule.root_user_accessed.name
    target_id = "SendToSlack"
    arn = aws_sns_topic.slack_soc_use1.arn
}

resource "aws_cloudwatch_event_target" "opsgenie_root_user_accessed" {
    provider = aws.use1
    rule = aws_cloudwatch_event_rule.root_user_accessed.name
    target_id = "SendToOpsgenie"
    arn = aws_sns_topic.opsgenie_alert_use1.arn
}