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
    role_arn = aws_iam_role.root_user_accessed.arn
}

resource "aws_cloudwatch_event_target" "opsgenie_root_user_accessed" {
    rule = aws_cloudwatch_event_rule.root_user_accessed.name
    target_id = "SendToOpsGenie"
    arn = aws_sns_topic.opsgenie_alert.arn
    role_arn = aws_iam_role.root_user_accessed.arn
}

resource "aws_iam_role" "root_user_accessed" {
  name_prefix        = "account-root-user-notification-"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.root_user_accessed_assume_role.json
}

data "aws_iam_policy_document" "root_user_accessed_assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "root_user_accessed_base" {
  name   = "base"
  role   = aws_iam_role.root_user_accessed.id
  policy = data.aws_iam_policy_document.root_user_accessed_base.json
}

data "aws_iam_policy_document" "root_user_accessed_base" {
  statement {
    sid    = "base"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.slack_soc.arn,
      aws_sns_topic.opsgenie_alert.arn
    ]
  }
}