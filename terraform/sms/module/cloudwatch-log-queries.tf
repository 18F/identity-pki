resource "aws_cloudwatch_query_definition" "default" {
  for_each = yamldecode(templatefile("${path.module}/cloudwatch-log-queries.yml", { "env" = var.env }))

  name            = "login-sms-${var.env}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

