resource "aws_route53_zone" "pivcac_zone" {
  name = "pivcac.${var.env_name}.${var.root_domain}"
}

resource "aws_route53_record" "pivcac_zone_delegation" {
  zone_id = var.route53_id
  name    = "pivcac.${var.env_name}.${var.root_domain}"
  type    = "NS"
  ttl     = "30"
  records = [
    aws_route53_zone.pivcac_zone.name_servers[0],
    aws_route53_zone.pivcac_zone.name_servers[1],
    aws_route53_zone.pivcac_zone.name_servers[2],
    aws_route53_zone.pivcac_zone.name_servers[3],
  ]
}

resource "aws_route53_record" "pivcac_external" {
  zone_id = aws_route53_zone.pivcac_zone.id
  name    = "*.pivcac.${var.env_name}.${var.root_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.pivcac.dns_name]
}

##### DNSSEC #####

module "dnssec" {
  source = "github.com/18F/identity-terraform//dnssec?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/dnssec"

  dnssec_ksks_action_req_alarm_desc = "${local.dnssec_runbook_prefix}_ksks_action_req"
  dnssec_ksk_age_alarm_desc         = "${local.dnssec_runbook_prefix}_ksk_age"
  dnssec_errors_alarm_desc          = "${local.dnssec_runbook_prefix}_errors"
  dnssec_zone_name                  = aws_route53_zone.pivcac_zone.name
  dnssec_zone_id                    = aws_route53_zone.pivcac_zone.id
  alarm_actions                     = local.moderate_priority_alarm_actions
  protect_resources                 = false
  # ^ don't create an IAM policy preventing disabling/deletion of pivcac DNSSEC stuff
}

resource "aws_route53_record" "pivcac_zone_ds" {
  zone_id = var.route53_id
  name    = aws_route53_zone.pivcac_zone.name
  type    = "DS"
  ttl     = "300"
  records = [module.dnssec.active_ds_value]
}

