locals {
  dnssec_runbook_prefix = " - https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-DNS#dnssec"
}

# Tooling specific subdomain
resource "aws_route53_zone" "primary" {
  name = var.dns_domain
}

data "aws_sns_topic" "events" {
  name = var.events_sns_topic
}

module "dnssec" {
  source = "github.com/18F/identity-terraform//dnssec?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/dnssec"

  dnssec_ksks_action_req_alarm_desc = "${local.dnssec_runbook_prefix}_ksks_action_req"
  dnssec_ksk_age_alarm_desc         = "${local.dnssec_runbook_prefix}_ksk_age"
  dnssec_errors_alarm_desc          = "${local.dnssec_runbook_prefix}_errors"
  dnssec_zone_name                  = var.dns_domain
  dnssec_zone_id                    = aws_route53_zone.primary.id
  alarm_actions                     = [data.aws_sns_topic.events.arn]
  protect_resources                 = true
}
