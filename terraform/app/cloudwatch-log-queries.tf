resource "aws_cloudwatch_query_definition" "default" {
  for_each = yamldecode(templatefile("cloudwatch-log-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

