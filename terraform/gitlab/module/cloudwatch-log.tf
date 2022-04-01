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

resource "aws_cloudwatch_log_group" "all_gitlab_logs" {
  name              = "${var.env_name}_all_gitlab_logs"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_access_log" {
  name              = "${var.env_name}_gitlab_access_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_error_log" {
  name              = "${var.env_name}_gitlab_error_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "gitlab_audit_log" {
  name              = "${var.env_name}_gitlab_audit_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
resource "aws_cloudwatch_log_group" "gitlab_application_log" {
  name              = "${var.env_name}_gitlab_application_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
resource "aws_cloudwatch_log_group" "gitlab_backup_log" {
  name              = "${var.env_name}_gitlab_backup_log"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}
