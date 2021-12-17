#create Event rule
resource "aws_cloudwatch_event_rule" "guardduty_event_rule" {
  name        = "GuardDutyFindings"
  description = "Send GuardDuty findings to CW Log Groups"
  tags = {
    "Name" = "GuardDuty Findings"
  }

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.guardduty"
      ],
      "detail-type" : [
        "GuardDuty Finding"
      ]
    }
  )
}
#create CW Log group
resource "aws_cloudwatch_log_group" "guard_duty_log_group" {
  name              = "GuardDutyFindings/LogGroup"
  retention_in_days = 365
  tags = {
    "Name" = "GuardDuty findings"
  }
}

#add CW Log group to store logs.
resource "aws_cloudwatch_event_target" "cw_target_to_cw_logs" {
  rule      = aws_cloudwatch_event_rule.guardduty_event_rule.name
  target_id = "SendToCWLogGroup"
  arn       = "${aws_cloudwatch_log_group.guard_duty_log_group.arn}:*"
}

#Provides a CW events to manage a CloudWatch log resource policy
data "aws_iam_policy_document" "cw-event-log-publishing-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws:logs:*:*:*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com", "events.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "cw-rule-log-publishing-policy" {
  policy_document = data.aws_iam_policy_document.cw-event-log-publishing-policy.json
  policy_name     = "cw-rule-log-publishing-policy"
}