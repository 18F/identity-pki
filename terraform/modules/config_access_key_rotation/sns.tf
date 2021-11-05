resource "aws_sns_topic" "config_access_key_rotation_topic" {
  name              = "${var.config_access_key_rotation_name}-topic"
  display_name      = "${var.config_access_key_rotation_name}-topic"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_policy" "config_access_key_rotation_topic_policy" {
  arn    = aws_sns_topic.config_access_key_rotation_topic.arn
  policy = data.aws_iam_policy_document.config_access_key_rotation_topic_policy.json
}

data "aws_iam_policy_document" "config_access_key_rotation_topic_policy" {
  statement {
    sid    = "${var.config_access_key_rotation_name}-topic-policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.config_access_key_rotation_accounts
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      "${aws_sns_topic.config_access_key_rotation_topic.arn}"
    ]
  }
}

resource "aws_sns_topic_subscription" "config_access_key_rotation_lambda_target" {
  topic_arn = aws_sns_topic.config_access_key_rotation_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.config_access_key_rotation_lambda.arn
}