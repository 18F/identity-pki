module "cloudwatch_log_base_queries" {
  source   = "../../modules/cloudwatch_log_queries"
  env_name = var.env_name
  region   = var.region
  db_types = {
    "analytics" = "analytics"
  }
}

resource "aws_cloudwatch_query_definition" "analytics" {
  for_each = yamldecode(templatefile("${path.module}/cloudwatch-log-analytics-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

