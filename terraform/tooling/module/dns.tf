# Tooling specific subdomain
resource "aws_route53_zone" "primary" {
  name = var.dns_domain
}

data "aws_sns_topic" "events" {
  name = var.events_sns_topic
}

module "dnssec" {
  source = "../../modules/dnssec/"
  providers = {
    aws.usw2 = aws.usw2
    aws.use1 = aws.use1
  }

  dnssec_zone_name = var.dns_domain
  alarm_actions    = [data.aws_sns_topic.events.arn]
}
