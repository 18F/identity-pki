#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "ami_cleanup_lambda_assume" {
  statement {
    sid    = "Assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "ami_cleanup_lambda" {
  statement {
    sid    = "AllowCloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ami_cleanup_log_group.arn}:*"
    ]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DeleteSnapshot"
    ]
    resources = [
      "arn:aws:ec2:*::snapshot/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DeregisterImage"
    ]
    resources = [
      "arn:aws:ec2:*::image/*"
    ]
  }
}

resource "aws_iam_role" "lambda_ami_cleanup" {
  name_prefix        = "lambda_ami_cleanup"
  assume_role_policy = data.aws_iam_policy_document.ami_cleanup_lambda_assume.json
}

resource "aws_iam_role_policy" "ami_cleanup_lambda" {
  name   = "CloudWatchAndEC2"
  role   = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ami_cleanup_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.ami_cleanup.function_name}"
  retention_in_days = 30
}

module "ami_cleanup_function_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "ami_cleanup.py"
  source_dir           = "${path.module}/files/"

  zip_filename = "ami_cleanup.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "ami_cleanup" {
  filename         = module.ami_cleanup_function_code.zip_output_path
  function_name    = "ami_cleanup"
  description      = "Lambda function to remove old or unused AMIs"
  role             = aws_iam_role.lambda_ami_cleanup.arn
  handler          = "ami_cleanup.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  source_code_hash = module.ami_cleanup_function_code.zip_output_base64sha256
  publish          = false

  depends_on = [module.ami_cleanup_function_code.resource_check]
}

resource "aws_cloudwatch_event_rule" "run_ami_cleanup" {
  name                = "Run-ami_cleanup"
  description         = "Fires every 8 hours"
  schedule_expression = "cron(0 8 ? * * *)"
}

resource "aws_cloudwatch_event_target" "target_ami_cleanup" {
  rule      = aws_cloudwatch_event_rule.run_ami_cleanup.name
  target_id = aws_lambda_function.ami_cleanup.function_name
  arn       = aws_lambda_function.ami_cleanup.arn

  input = "{\"expireUnassociatedinDays\":\"${var.expire_unassociated_in_days}\",\"expireAssociatedinDays\": \"${var.expire_associated_in_days}\",\"dryRun\": \"\" }"
}

resource "aws_lambda_permission" "cloudwatch_to_ami_cleanup" {
  statement_id  = "AWSEvents_Run-ami_cleanup_Id425665071155"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_ami_cleanup.arn

  lifecycle {
    create_before_destroy = true
  }
}
