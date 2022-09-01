provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  verified_identity_alnum = join("", regexall("[a-z]+", var.ses_verified_identity))
}

###SQS queue###
resource "aws_sqs_queue" "ses_feedback_queue" {
  name                      = "ses_feedback_queue"
  message_retention_seconds = 1209600
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ses_dead_letter_queue.arn}\",\"maxReceiveCount\":4}"
  kms_master_key_id         = aws_kms_key.sqs_key.key_id
}

resource "aws_sqs_queue" "ses_dead_letter_queue" {
  name                      = "ses_dead_letter_queue"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.sqs_key.key_id
}

resource "aws_sns_topic" "ses_feedback_topic" {
  name = "ses-send-notifications-${local.verified_identity_alnum}"
}

resource "aws_sns_topic_subscription" "ses_feedback_subscription" {
  topic_arn = aws_sns_topic.ses_feedback_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_feedback_queue.arn
}

resource "aws_ses_identity_notification_topic" "ses_bounce" {
  topic_arn                = aws_sns_topic.ses_feedback_topic.arn
  notification_type        = "Bounce"
  identity                 = var.ses_verified_identity
  include_original_headers = false
}

resource "aws_ses_identity_notification_topic" "ses_complaint" {
  topic_arn                = aws_sns_topic.ses_feedback_topic.arn
  notification_type        = "Complaint"
  identity                 = var.ses_verified_identity
  include_original_headers = false
}

resource "aws_ses_identity_notification_topic" "ses_delivery" {
  topic_arn                = aws_sns_topic.ses_feedback_topic.arn
  notification_type        = "Delivery"
  identity                 = var.ses_verified_identity
  include_original_headers = false
}

data "aws_iam_policy_document" "ses_feedback_queue_iam_policy" {
  policy_id = "SESFeedbackQueueTopic"
  statement {
    sid       = "SESFeedbackQueueTopic"
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = ["${aws_sqs_queue.ses_feedback_queue.arn}"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = ["${aws_sns_topic.ses_feedback_topic.arn}"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "ses_queue_policy" {
  queue_url = aws_sqs_queue.ses_feedback_queue.id
  policy    = data.aws_iam_policy_document.ses_feedback_queue_iam_policy.json
}

###Lambda###

resource "aws_lambda_function" "SESFeedbackEvalLambda" {
  filename      = data.archive_file.ses_feedback_evaluation_function.output_path
  function_name = "SESLambda_${local.verified_identity_alnum}"
  role          = aws_iam_role.ses_feedback_eval_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  description   = "Lambda processing the SES feedback notifications"
}

data "archive_file" "ses_feedback_evaluation_function" {
  type        = "zip"
  source_file = "${path.module}/python/lambda_function.py"
  output_path = "${path.module}/python/lambda_function.py.zip"
}

data "aws_iam_policy_document" "ses_feedback_eval_lambda_role_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ses_feedback_eval_lambda_role" {
  name               = "SESFeedbackEvalLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.ses_feedback_eval_lambda_role_iam_policy.json
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.ses_feedback_queue.arn
  function_name    = aws_lambda_function.SESFeedbackEvalLambda.arn
}

resource "aws_iam_policy" "ses_feedback_eval_lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.ses_lambda_cw_logs.arn}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : [aws_kms_key.sqs_key.arn]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          aws_sqs_queue.ses_feedback_queue.arn,
          aws_sqs_queue.ses_dead_letter_queue.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_lambda_logs" {
  role       = aws_iam_role.ses_feedback_eval_lambda_role.name
  policy_arn = aws_iam_policy.ses_feedback_eval_lambda_policy.arn
}

####Cloudwatchlog group
resource "aws_cloudwatch_log_group" "ses_lambda_cw_logs" {
  name              = "/aws/lambda/SESLambda_${local.verified_identity_alnum}"
  retention_in_days = 365
}
