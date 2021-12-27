locals {
  retention_days = (var.env_name == "prod" || var.env_name == "staging" ? "3653" : "30")
}

resource "aws_cloudwatch_log_group" "kms_log" {
  name = "${var.env_name}_/srv/idp/shared/log/kms.log"

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "squid_access_log" {
  name = "${var.env_name}_/var/log/squid/access.log"

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "dns_query_log" {
  name              = "${var.env_name}/dns/query"
  retention_in_days = 365

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "ubuntu_advantage" {
  name              = "${var.env_name}_/var/log/ubuntu-advantage.log"
  retention_in_days = local.retention_days

  tags = {
    environment = var.env_name
  }
}


resource "aws_cloudwatch_log_group" "idp_events" {
  name              = "${var.env_name}_/srv/idp/shared/log/events.log"
  retention_in_days = local.retention_days
}

# Log group for reimported scrubbed messages in case of PII spill
resource "aws_cloudwatch_log_group" "idp_events_scrubbed" {
  name              = "${var.env_name}_scrubbed_/srv/idp/shared/log/events.log"
  retention_in_days = local.retention_days
}

resource "aws_cloudwatch_log_group" "idp_production" {
  name              = "${var.env_name}_/srv/idp/shared/log/production.log"
  retention_in_days = local.retention_days
}

resource "aws_cloudwatch_log_group" "idp_reports" {
  name              = "${var.env_name}_/srv/idp/shared/log/reports.log"
  retention_in_days = local.retention_days
}

resource "aws_cloudwatch_log_group" "idp_telephony" {
  name              = "${var.env_name}_/srv/idp/shared/log/telephony.log"
  retention_in_days = local.retention_days
}

resource "aws_cloudwatch_log_group" "idp_workers" {
  name              = "${var.env_name}_/srv/idp/shared/log/workers.log"
  retention_in_days = local.retention_days
}

