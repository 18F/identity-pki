# Keeps us from having to parse out each resource name
data "aws_arn" "resources" {
  for_each = toset(
    concat(
      var.aws_shield_resources["cloudfront"],
      var.aws_shield_resources["route53_hosted_zone"],
      var.aws_shield_resources["global_accelerator"],
      var.aws_shield_resources["application_loadbalancer"],
      var.aws_shield_resources["classic_loadbalancer"],
      var.aws_shield_resources["elastic_ip_address"]
    )
  )
  arn = each.value
}

resource "aws_shield_protection" "resources" {
  for_each = toset(
    concat(
      var.aws_shield_resources["cloudfront"],
      var.aws_shield_resources["route53_hosted_zone"],
      var.aws_shield_resources["global_accelerator"],
      var.aws_shield_resources["application_loadbalancer"],
      var.aws_shield_resources["classic_loadbalancer"],
      var.aws_shield_resources["elastic_ip_address"]
    )
  )
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
  source = "../../modules/shield_ddos"
  depends_on = [ aws_shield_protection.resources ]
  for_each = toset(var.aws_shield_resources["cloudfront"])
  
  resource_arn = each.value
  action = var.automated_ddos_protection_action 
}
