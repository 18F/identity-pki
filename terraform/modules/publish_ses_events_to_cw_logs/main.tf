#provider "aws" {
#  region = var.region
#}

data "aws_caller_identity" "current" {}

###SQS queue###
resource "aws_sqs_queue" "ses_all_events_queue" {
  name                      = var.ses_events_queue
  message_retention_seconds = 1209600
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ses_all_events_dlq.arn}\",\"maxReceiveCount\":4}"
  kms_master_key_id         = aws_kms_key.sqs_key.key_id
}

resource "aws_sqs_queue" "ses_all_events_dlq" {
  name              = var.ses_events_dlq
  kms_master_key_id = aws_kms_key.sqs_key.key_id
}

resource "aws_sns_topic_subscription" "ses_events_subscription" {
  topic_arn = aws_sns_topic.ses_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_all_events_queue.arn
}

data "aws_iam_policy_document" "ses_events_queue_iam_policy" {
  statement {
    sid       = "SESEventsQueueTopic"
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = ["${aws_sqs_queue.ses_all_events_queue.arn}"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = ["${aws_sns_topic.ses_events.arn}"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "ses_events_queue_policy" {
  queue_url = aws_sqs_queue.ses_all_events_queue.id
  policy    = data.aws_iam_policy_document.ses_events_queue_iam_policy.json
}

###Lambda###
resource "aws_lambda_function" "SESEventsEvalLambda" {
  filename      = data.archive_file.ses_events_evaluation_function.output_path
  function_name = var.ses_events_lambda
  role          = aws_iam_role.ses_events_eval_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  description   = "Lambda processing the SES events captured from configuration sets"
}

data "archive_file" "ses_events_evaluation_function" {
  type        = "zip"
  source_file = "${path.module}/python/lambda_function.py"
  output_path = "${path.module}/python/lambda_function.py.zip"
}

data "aws_iam_policy_document" "ses_events_eval_lambda_role_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ses_events_eval_lambda_role" {
  assume_role_policy = data.aws_iam_policy_document.ses_events_eval_lambda_role_iam_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_ses_role_policy" {
  role       = aws_iam_role.ses_events_eval_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_event_source_mapping" "ses_event_source_mapping" {
  event_source_arn = aws_sqs_queue.ses_all_events_queue.arn
  function_name    = aws_lambda_function.SESEventsEvalLambda.arn
}

resource "aws_iam_policy" "ses_events_eval_lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.ses_events_lambda_cw_logs.arn}:*"
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
          aws_sqs_queue.ses_all_events_queue.arn,
          aws_sqs_queue.ses_all_events_dlq.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_lambda" {
  role       = aws_iam_role.ses_events_eval_lambda_role.name
  policy_arn = aws_iam_policy.ses_events_eval_lambda_policy.arn
}

####Cloudwatchlog group
resource "aws_cloudwatch_log_group" "ses_events_lambda_cw_logs" {
  name              = "/aws/lambda/${var.ses_events_lambda}"
  retention_in_days = 365
}