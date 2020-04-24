resource "aws_route53_zone" "pivcac_zone" {
  name  = "pivcac.${var.env_name}.${var.root_domain}"
  count = var.pivcac_service_enabled
}

resource "aws_route53_record" "pivcac_zone_delegation" {
  zone_id = var.route53_id
  name    = "pivcac.${var.env_name}.${var.root_domain}"
  type    = "NS"
  ttl     = "30"
  count   = var.pivcac_service_enabled
  records = [
    aws_route53_zone.pivcac_zone[0].name_servers[0],
    aws_route53_zone.pivcac_zone[0].name_servers[1],
    aws_route53_zone.pivcac_zone[0].name_servers[2],
    aws_route53_zone.pivcac_zone[0].name_servers[3],
  ]
}

resource "aws_route53_record" "pivcac_external" {
  zone_id = aws_route53_zone.pivcac_zone[0].id
  name    = "*.pivcac.${var.env_name}.${var.root_domain}"
  type    = "CNAME"
  ttl     = "300"
  count   = var.pivcac_service_enabled
  records = [aws_elb.pivcac[0].dns_name]
}

data "aws_iam_policy_document" "pivcac_route53_modification" {
  count = var.pivcac_service_enabled
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
      "arn:aws:route53:::hostedzone/${aws_route53_zone.pivcac_zone[0].id}",
    ]
  }
}

resource "aws_iam_role_policy" "pivcac_update_route53" {
  name   = "${var.env_name}-pivcac_update_route53"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.pivcac_route53_modification[0].json
  count  = var.pivcac_service_enabled
}

