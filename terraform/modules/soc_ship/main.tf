locals {
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-cloudtrail-lg"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  count          = length(var.cloudwatch_log_group_name)
  name           = var.cloudwatch_subscription_filter_name
  log_group_name = var.cloudwatch_log_group_name[count.index]
  filter_pattern = var.cloudwatch_filter_pattern

  destination_arn = local.soc_destination_arn
  distribution    = "ByLogStream"

  role_arn = aws_iam_role.cloudwatch_logs_role.arn
}