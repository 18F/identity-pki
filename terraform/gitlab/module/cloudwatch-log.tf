resource "aws_cloudwatch_log_group" "dns_query_log" {
  name              = "${var.env_name}/dns/query"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "${var.env_name}_flow_log_group"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
