data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "usps_topic" {
  name = "usps-${var.env_name}-topic"

  http_success_feedback_role_arn    = aws_iam_role.usps_SNSSuccessFeedback.arn
  http_failure_feedback_role_arn    = aws_iam_role.usps_SNSFailureFeedback.arn
  http_success_feedback_sample_rate = 100
}

resource "aws_sns_topic_policy" "usps_topic_policy" {
  arn = aws_sns_topic.usps_topic.arn

  policy = data.aws_iam_policy_document.usps_topic_policy.json
}

data "aws_iam_policy_document" "usps_topic_policy" {

  statement {
    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.usps_topic.arn
    ]
  }

}

resource "aws_iam_role" "usps_SNSSuccessFeedback" {
  name                = "usps_${var.env_name}_SNSSuccessFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.usps_SNSFeedback_policy.arn]
}

resource "aws_iam_role" "usps_SNSFailureFeedback" {
  name                = "usps_${var.env_name}_SNSFailureFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.usps_SNSFeedback_policy.arn]
}

data "aws_iam_policy_document" "sns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "usps_SNSFeedback_policy" {
  name   = "uspsSNSFeedbackPolicy"
  policy = data.aws_iam_policy_document.usps_SNSFeedback_policy_document.json
}

data "aws_iam_policy_document" "usps_SNSFeedback_policy_document" {
  statement {
    sid    = "AllowFeedback"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.usps_success_sns_log.arn}:*", "${aws_cloudwatch_log_group.usps_failure_sns_log.arn}:*"]
  }
}

resource "aws_cloudwatch_log_group" "usps_success_sns_log" {
  name = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/usps-${var.env_name}-topic"
}

resource "aws_cloudwatch_log_group" "usps_failure_sns_log" {
  name = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/usps-${var.env_name}-topic/Failure"
}
