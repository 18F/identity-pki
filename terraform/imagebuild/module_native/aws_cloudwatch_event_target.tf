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