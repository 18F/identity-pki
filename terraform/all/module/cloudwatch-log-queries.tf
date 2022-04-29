resource "aws_cloudwatch_query_definition" "default" {
  for_each = yamldecode(templatefile("${path.module}/cloudwatch-log-queries.yml", { "account_name" = var.iam_account_alias }))

  name            = "${var.iam_account_alias}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}

