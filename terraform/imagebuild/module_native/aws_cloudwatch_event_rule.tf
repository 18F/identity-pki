resource "aws_cloudwatch_event_rule" "nightly_trigger" {
  name        = "${var.name}-${var.env_name}-nightly-codepipeline"
  description = "Trigger Image Builds Nightly for ${var.env_name}"

  schedule_expression = "cron(0 12 * * ? *)"
}