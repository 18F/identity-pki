resource "aws_cloudwatch_event_rule" "guardduty_event_rule" {
  name        = "GuardDutyFindings"
  description = "Capture GuardDuty high severity findings and trigger CW Log Group"
  tags = {
    "Name" = "GuardDuty Findings"
  }

  event_pattern = <<PATTERN
{
   "source":
         ["aws.guardduty"],
    "detail-type":
        ["GuardDuty Finding"],
    "detail":
        {"severity":[6.9,7.0,7.1,7.2,7.3,7.4,7.5,7.6,7.7,7.8,7.9,8.0,8.1,8.2,8.3,8.4,8.5,8.6,8.7,8.8,8.9]}}
PATTERN
}

#create CW Log group
resource "aws_cloudwatch_log_group" "guard_duty_log_group" {
  name              = "GuardDutyFindings/LogGroup"
  retention_in_days = 365
  tags = {
    "Name" = "Guard Duty findings log group name"
  }
}

#add CW Log group to store logs.
resource "aws_cloudwatch_event_target" "cw_target_to_cw_logs" {
  rule      = aws_cloudwatch_event_rule.guardduty_event_rule.name
  target_id = "SendToCWLogGroup"
  arn       = substr(aws_cloudwatch_log_group.guard_duty_log_group.arn, 0, length(aws_cloudwatch_log_group.guard_duty_log_group.arn) - 2)
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