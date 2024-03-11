locals {
  fn_CloudtrailResponder_lambda_name = "fn_CloudTrailResponder"
}
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "fn_CloudTrailResponder_lambda_assume" {
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
data "aws_iam_policy_document" "fn_CloudTrailResponder_lambda" {
  statement {
    sid    = "AllowForCTResponder"
    effect = "Allow"
    actions = [
      "cloudtrail:CreateTrail",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:StartLogging",
      "cloudtrail:UpdateTrail",
      "cloudtrail:DescribeTrails",
      "sns:Publish",
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "lambda_fn_CloudTrailResponder" {
  name               = "Detect-if-CloudTrail-is-disabled-rLambdaCTRole"
  assume_role_policy = data.aws_iam_policy_document.fn_CloudTrailResponder_lambda_assume.json
}

resource "aws_iam_role_policy" "fn_CloudTrailResponder_lambda" {
  name   = "rLambdaCTRole"
  role   = aws_iam_role.lambda_fn_CloudTrailResponder.id
  policy = data.aws_iam_policy_document.fn_CloudTrailResponder_lambda.json

}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "fn_CloudTrailResponder" {
  name              = "/aws/lambda/${local.fn_CloudtrailResponder_lambda_name}"
  retention_in_days = 30
}

module "fn_CloudTrailResponder_function_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "index.py"
  source_dir           = "${path.module}/lambda/fn_CloudTrailResponder"
  zip_filename         = "${path.module}/lambda/fn_CloudTrailResponder.zip"
}


#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "fn_CloudTrailResponder" {
  filename         = module.fn_CloudTrailResponder_function_code.zip_output_path
  function_name    = local.fn_CloudtrailResponder_lambda_name
  role             = aws_iam_role.lambda_fn_CloudTrailResponder.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.6"
  timeout          = 3
  source_code_hash = module.fn_CloudTrailResponder_function_code.zip_output_base64sha256
  publish          = false

  depends_on = [module.fn_CloudTrailResponder_function_code.resource_check]
}

resource "aws_cloudwatch_event_rule" "detect_if_cloudtrail_is_disabled" {
  name = "Detect-if-CloudTrail-is-disabled-rEventRule"
  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"],
    source      = ["aws.cloudtrail"],
    detail = {
      eventSource = ["cloudtrail.amazonaws.com"],
    eventName = ["DeleteTrail", "StopLogging"] }
  })
}


resource "aws_cloudwatch_event_target" "target_fn_CloudTrailResponder" {
  rule      = aws_cloudwatch_event_rule.detect_if_cloudtrail_is_disabled.name
  target_id = "TargetFunctionV1"
  arn       = aws_lambda_function.fn_CloudTrailResponder.arn

}

resource "aws_lambda_permission" "cloudwatch_to_fn_CloudTrailResponder" {
  statement_id  = "Detect-if-CloudTrail-is-disabled-rPermissionForEventsToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn_CloudTrailResponder.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_if_cloudtrail_is_disabled.arn

}
