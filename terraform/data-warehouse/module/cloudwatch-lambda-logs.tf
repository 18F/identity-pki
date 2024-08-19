resource "aws_cloudwatch_log_group" "db_consumption" {
  name              = "/aws/lambda/${local.db_consumption_lambda_name}"
  retention_in_days = local.logs_retention_days

  tags = {
    environment = var.env_name
  }
}
