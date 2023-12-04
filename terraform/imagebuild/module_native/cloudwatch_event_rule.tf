locals {
  retention_days = (var.env_name == "prod" || var.env_name == "staging" ? "3653" : "30")
}

resource "aws_cloudwatch_log_group" "imagebuild_base" {
  name              = "/aws/codebuild/${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild-base"
  retention_in_days = local.retention_days

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "imagebuild_rails" {
  name              = "/aws/codebuild/${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild-rails"
  retention_in_days = local.retention_days

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_event_rule" "nightly_trigger" {
  name        = "${var.name}-${var.env_name}-nightly-codepipeline"
  description = "Trigger Image Builds Nightly for ${var.env_name}"

  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "nightly_base" {
  count    = var.nightly_build_trigger ? 1 : 0
  rule     = aws_cloudwatch_event_rule.nightly_trigger.name
  arn      = aws_codepipeline.base_image.arn
  role_arn = aws_iam_role.cloudwatch_events.arn
}

resource "aws_cloudwatch_event_target" "nightly_rails" {
  count    = var.nightly_build_trigger ? 1 : 0
  rule     = aws_cloudwatch_event_rule.nightly_trigger.name
  arn      = aws_codepipeline.rails_image.arn
  role_arn = aws_iam_role.cloudwatch_events.arn
}