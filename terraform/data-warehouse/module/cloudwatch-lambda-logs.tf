resource "aws_cloudwatch_log_group" "db_consumption" {
  name              = "/aws/lambda/${var.env_name}-db-consumption"
  retention_in_days = local.logs_retention_days

  tags = {
    environment = var.env_name
  }
}
