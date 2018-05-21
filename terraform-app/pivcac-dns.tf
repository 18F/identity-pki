resource "aws_route53_zone" "pivcac_zone" {
  name = "pivcac.${var.env_name}.${var.root_domain}"
}

resource "aws_route53_record" "pivcac_external" {
  zone_id = "${aws_route53_zone.pivcac_zone.id}"
  name = "*.pivcac.${var.env_name}.${var.root_domain}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_elb.pivcac.dns_name}"]
}

data "aws_iam_policy_document" "pivcac_route53_modification" {
  statement {
    sid = "AllowPIVCACCertbotToDNS"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
       "arn:aws:route53:::hostedzone/${aws_route53_zone.pivcac_zone.id}"
    ]
  }
}

resource "aws_iam_role_policy" "pivcac_update_route53" {
  name = "${var.env_name}-pivcac_update_route53"
  role = "${aws_iam_role.pivcac.id}"
  policy = "${data.aws_iam_policy_document.pivcac_route53_modification.json}"
}
