# Keeps us from having to parse out each resource name
data "aws_arn" "resources" {
  for_each = toset(flatten(values(var.aws_shield_resources)))
  arn      = each.value
}

resource "aws_shield_protection" "resources" {
  for_each = toset(flatten(values(var.aws_shield_resources)))
  # Need replace to sanitize resource name of /
  name         = replace(data.aws_arn.resources[each.value].resource, "/", "-")
  resource_arn = each.value
  tags = {
    Environment = var.env
    Name        = data.aws_arn.resources[each.value].resource
    Service     = data.aws_arn.resources[each.value].service
    Region      = data.aws_arn.resources[each.value].region
  }
}

module "shield_ddos_toggle" {
  source     = "../../modules/shield_ddos"
  depends_on = [aws_shield_protection.resources]
  for_each   = toset(var.aws_shield_resources["cloudfront"])

  resource_arn = each.value
  action       = var.automated_ddos_protection_action
}
