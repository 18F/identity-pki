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

resource "aws_cloudwatch_log_metric_filter" "send_by_country" {
  name           = "SendByCountry"
  pattern        = "{ $.event_type = \"_SMS.SUCCESS\"}"
  log_group_name = aws_cloudwatch_log_group.pinpoint_event_logger.name

  metric_transformation {
    name      = "Country"
    namespace = "PinpointMetrics"
    value     = 1

    dimensions = {
      iso_country_code = "$.attributes.iso_country_code",
    }

    unit = "Count"
  }
}

data "external" "country_codes" {
  program = [
    "aws", "route53", "list-geo-locations",
    "--query", "{\"country_codes\":to_string(GeoLocationDetailsList[?not_null(CountryCode)] | [?length(CountryCode) == `2`].CountryCode)}"
  ]
}

locals {
  country_codes = toset(jsondecode(data.external.country_codes.result.country_codes))
}

resource "aws_cloudwatch_metric_alarm" "send_by_country" {
  for_each            = local.country_codes
  alarm_name          = "sms-${each.key}-country-anomaly"
  evaluation_periods  = "2"
  threshold_metric_id = "e1"

  comparison_operator = "GreaterThanUpperThreshold"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1,30)"
    label       = "Sent (Expected)"
    return_data = true
  }

  metric_query {
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "Country"
      namespace   = "PinpointMetrics"
      period      = "360"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        iso_country_code = each.key
      }
    }
  }
}

module "lambda_zip" {
  source = "github.com/18F/identity-terraform//null_archive?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

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
