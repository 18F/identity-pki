data "aws_region" "current" {}

resource "aws_iam_role" "pinpoint_event_logger_role" {
  name               = "${var.env}-pinpoint-event-logger-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.pinpoint_event_logger_role_trust.json
}

data "aws_iam_policy_document" "pinpoint_event_logger_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "pinpoint_event_logger_trust_attach" {
  role       = aws_iam_role.pinpoint_event_logger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "pinpoint_event_logger_policy_doc" {
  statement {
    actions = [
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:Describe*",
    ]
    resources = [
      aws_kinesis_stream.pinpoint_kinesis_stream.arn,
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.pinpoint_event_logger.arn}:*",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "pinpoint_event_logger_policy" {
  name        = "${var.env}-pinpoint-event-logger-policy-${data.aws_region.current.name}"
  description = "PinPoint Event Logger"
  policy      = data.aws_iam_policy_document.pinpoint_event_logger_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "pinpoint_event_logger_policy_attach" {
  role       = aws_iam_role.pinpoint_event_logger_role.name
  policy_arn = aws_iam_policy.pinpoint_event_logger_policy.arn
}

resource "aws_cloudwatch_log_group" "pinpoint_event_logger" {
  name              = "/aws/lambda/${var.pinpoint_event_logger_lambda_name}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_metric_filter" "successful_send_by_country" {
  name           = "SuccessfulSMSByCountry"
  pattern        = "{ $.event_type = \"_SMS.SUCCESS\"}"
  log_group_name = aws_cloudwatch_log_group.pinpoint_event_logger.name

  metric_transformation {
    name      = "SuccessfulSMS"
    namespace = "PinpointMetrics"
    value     = 1

    dimensions = {
      iso_country_code = "$.attributes.iso_country_code",
    }

    unit = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "successful_send_all" {
  name           = "SuccessfulSMSAll"
  pattern        = "{ $.event_type = \"_SMS.SUCCESS\"}"
  log_group_name = aws_cloudwatch_log_group.pinpoint_event_logger.name

  metric_transformation {
    name      = "SuccessfulSMS"
    namespace = "PinpointMetrics"
    value     = 1

    unit = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_send_by_country" {
  name           = "FailedSMSByCountry"
  pattern        = "{ $.event_type = \"_SMS.FAILURE\"}"
  log_group_name = aws_cloudwatch_log_group.pinpoint_event_logger.name

  metric_transformation {
    name      = "FailedSMS"
    namespace = "PinpointMetrics"
    value     = 1

    dimensions = {
      iso_country_code = "$.attributes.iso_country_code",
    }

    unit = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_send_all" {
  name           = "FailedSMSAll"
  pattern        = "{ $.event_type = \"_SMS.FAILURE\"}"
  log_group_name = aws_cloudwatch_log_group.pinpoint_event_logger.name

  metric_transformation {
    name      = "FailedSMS"
    namespace = "PinpointMetrics"
    value     = 1

    unit = "Count"
  }
}

data "http" "phone_support" {
  url = var.sms_support_api_endpoint

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  supported_country_codes      = toset([for key, value in jsondecode(data.http.phone_support.response_body).countries : key if value.supports_sms])
  ignored_country_codes        = toset(var.ignored_countries)
  alarm_volume_alert_countries = setsubtract(local.supported_country_codes, local.ignored_country_codes)
}

resource "aws_cloudwatch_metric_alarm" "send_by_country" {
  for_each          = local.alarm_volume_alert_countries
  alarm_name        = "sms-country-${each.key}-volume-too-high"
  alarm_description = <<EOM
${var.env}: More than 100 SMS have been sent to phone numbers in ${each.key} in the last hour. This may a problem with delivery or malicious usage.
See https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice#sms-delivery
EOM

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  threshold           = lookup(var.sms_unexpected_individual_country_alarm_thresholds, each.key, var.sms_unexpected_country_alarm_default_threshold)
  treat_missing_data  = "notBreaching"
  alarm_actions       = [data.aws_sns_topic.alert_warning.arn]

  metric_query {
    id          = "total_send"
    expression  = "(successful_send + failed_send)"
    label       = "Total SMS Send Attempts"
    return_data = "true"
  }

  metric_query {
    id = "failed_send"

    metric {
      metric_name = "FailedSMS"
      namespace   = "PinpointMetrics"
      period      = 3600
      stat        = "Sum"

      dimensions = {
        iso_country_code = each.key
      }
    }
  }

  metric_query {
    id = "successful_send"

    metric {
      metric_name = "SuccessfulSMS"
      namespace   = "PinpointMetrics"
      period      = 3600
      stat        = "Sum"

      dimensions = {
        iso_country_code = each.key
      }
    }
  }
}

module "lambda_zip" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "pinpoint_event_logger.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "pinpoint_event_logger.py.zip"
}


resource "aws_lambda_function" "pinpoint_event_logger" {
  depends_on = [
    aws_cloudwatch_log_group.pinpoint_event_logger,
    aws_iam_role.pinpoint_event_logger_role,
    module.lambda_zip.resource_check
  ]
  function_name    = var.pinpoint_event_logger_lambda_name
  description      = "Pinpoint Kinesis to CloudWatch Logging Function"
  filename         = module.lambda_zip.zip_output_path
  source_code_hash = module.lambda_zip.zip_output_base64sha256
  runtime          = "python3.9"
  handler          = "pinpoint_event_logger.lambda_handler"
  timeout          = 600
  memory_size      = 4096
  role             = aws_iam_role.pinpoint_event_logger_role.arn
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  depends_on        = [aws_kinesis_stream.pinpoint_kinesis_stream]
  event_source_arn  = aws_kinesis_stream.pinpoint_kinesis_stream.arn
  function_name     = aws_lambda_function.pinpoint_event_logger.arn
  starting_position = "LATEST"
  batch_size        = 10000
}
