resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  for_each        = var.cloudwatch_log_group_name
  name            = var.cloudwatch_subscription_filter_name
  log_group_name  = each.key
  filter_pattern  = each.value
  destination_arn = var.soc_destination_arn
  distribution    = "ByLogStream"
  role_arn        = aws_iam_role.cloudwatch_logs_role.arn
}
