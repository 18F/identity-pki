locals {
  cloudtrail_responder_sns_topic = aws_sns_topic.slack_usw2["otherevents"].arn
}

## This section is to capture the cloudformation stack and removes associated resources"
# This resources should be removed after 1 release.
resource "aws_cloudformation_stack" "fn_cloudtrail_old" {
  name = "Detect-if-CloudTrail-is-disabled"

  template_body = jsonencode(
    {
      Parameters = {}
      Resources = {
        OldSNSTopic = {
          Type = "AWS::SNS::Topic"
          Properties = {
            TopicName : "CTResponder"
          }
        }
      }
    }
  )
}
# End of previous statement.

data "aws_iam_policy_document" "cloudtrail_responder" {
  statement {
    sid    = "CTResponderModifyTrail"
    effect = "Allow"
    actions = [
      "cloudtrail:CreateTrail",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:StartLogging",
      "cloudtrail:UpdateTrail",
    ]
    resources = [
      aws_cloudtrail.cloudtrail.arn
    ]
  }
  statement {
    sid    = "CTResponderGetTrail"
    effect = "Allow"
    actions = [
      "cloudtrail:DescribeTrails",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "CTResponderSendMessage"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      local.cloudtrail_responder_sns_topic
    ]
  }
}

module "cloudtrail_responder" {
  source = "github.com/18F/identity-terraform//lambda_function?ref=c609906379b5705b55a916e9b9c52e716eb0611a"
  #source = "../../../../identity-terraform/lambda_function"

  # lambda function
  region               = var.region
  function_name        = "cloudtrail-responder"
  description          = "This function is to turn cloudtrail back on if someone turns it off"
  source_code_filename = "cloudtrail_responder.py"
  source_dir           = "${path.module}/lambda/cloudtrail-responder"
  runtime              = "python3.12"

  environment_variables = {
    "TRAIL_DETAILS" = jsonencode({
      "NAME"                          = aws_cloudtrail.cloudtrail.name
      "LOG_GROUP"                     = aws_cloudtrail.cloudtrail.cloud_watch_logs_group_arn
      "LOG_ROLE"                      = aws_cloudtrail.cloudtrail.cloud_watch_logs_role_arn
      "LOG_FILE_VALIDATION"           = aws_cloudtrail.cloudtrail.enable_log_file_validation
      "INCLUDE_GLOBAL_SERVICE_EVENTS" = aws_cloudtrail.cloudtrail.include_global_service_events
      "IS_MULTI_REGION"               = aws_cloudtrail.cloudtrail.is_multi_region_trail
      "S3_BUCKET_NAME"                = aws_cloudtrail.cloudtrail.s3_bucket_name
    })
    "DEBUG"     = true
    "SNS_TOPIC" = local.cloudtrail_responder_sns_topic
  }
  # Logging and alarms
  cloudwatch_retention_days = var.cloudwatch_retention_days
  alarm_actions             = [local.cloudtrail_responder_sns_topic]
  treat_missing_data        = "notBreaching"

  # IAM permissions
  lambda_iam_policy_document = data.aws_iam_policy_document.cloudtrail_responder.json
}

resource "aws_cloudwatch_event_rule" "cloudtrail_responder" {
  name = "cloudtrail-responder"
  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"],
    source      = ["aws.cloudtrail"],
    detail = {
      eventSource = ["cloudtrail.amazonaws.com"],
      eventName   = ["DeleteTrail", "StopLogging"],
    }
  })
}

resource "aws_cloudwatch_event_target" "target_cloudtrail_responder" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_responder.name
  target_id = "cloudtrail-responder-event-to-lambda"
  arn       = module.cloudtrail_responder.lambda_arn

}

resource "aws_lambda_permission" "cloudwatch_to_cloudtrail_responder" {
  statement_id  = "EventsServiceToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.cloudtrail_responder.lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudtrail_responder.arn
}
