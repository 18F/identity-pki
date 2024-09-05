resource "aws_cloudwatch_query_definition" "default" {
  for_each = yamldecode(templatefile("${path.module}/queries/cloudwatch-log-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

resource "aws_cloudwatch_query_definition" "ssm" {
  for_each = yamldecode(templatefile("${path.module}/queries/cloudwatch-log-ssm-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

resource "aws_cloudwatch_query_definition" "db" {
  for_each = yamldecode(templatefile("${path.module}/queries/cloudwatch-log-db-queries.yml", { "env" = var.env_name, "region" = var.region, "db_types" = var.db_types }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

resource "aws_cloudwatch_query_definition" "obproxy" {
  for_each = yamldecode(templatefile("${path.module}/queries/cloudwatch-log-obproxy-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

