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

data "aws_iam_policy_document" "pivcac_route53_modification" {
  statement {
    sid    = "AllowPIVCACCertbotToDNS01"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "AllowPIVCACCertbotToDNS02"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${aws_route53_zone.pivcac_zone.id}",
    ]
  }
}

resource "aws_iam_role_policy" "pivcac_update_route53" {
  name   = "${var.env_name}-pivcac_update_route53"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.pivcac_route53_modification.json
}

##### DNSSEC #####

module "dnssec" {
  source = "../modules/dnssec/"
  providers = {
    aws.usw2 = aws.usw2
    aws.use1 = aws.use1
  }

  dnssec_zone_name = aws_route53_zone.pivcac_zone.name
  dnssec_zone_id   = aws_route53_zone.pivcac_zone.id
  alarm_actions    = local.low_priority_alarm_actions
}


resource "aws_route53_record" "pivcac_zone_ds" {
  zone_id = var.route53_id
  name    = "pivcac.${var.env_name}.${var.root_domain}"
  type    = "DS"
  ttl     = "300"
  records = [module.dnssec.active_ds_value]
}

