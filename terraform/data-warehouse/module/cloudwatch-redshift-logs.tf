locals {
  redshift_log_groups = [
    "connectionlog",
    "useractivitylog",
    "userlog"
  ]
}

resource "aws_cloudwatch_log_group" "redshift_logs" {
  for_each = toset(local.redshift_log_groups)

  name = join("/", [
    "/aws/redshift/cluster/",
    "${var.env_name}-analytics",
    each.value
  ])
  retention_in_days = local.logs_retention_days
  skip_destroy      = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}
