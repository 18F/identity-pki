resource "aws_cloudwatch_event_rule" "root_user_accessed" {
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
    rule = aws_cloudwatch_event_rule.root_user_accessed.name
    target_id = "SendToSlack"
    arn = aws_sns_topic.slack_soc.arn
}
