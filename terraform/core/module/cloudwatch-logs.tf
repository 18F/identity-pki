resource "aws_cloudwatch_log_group" "ssm" {
  name              = "ssm"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = true
}
