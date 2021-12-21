# -- Resources --

resource "aws_route53_zone" "primary" {
  # domain, ensuring it has a trailing "."
  name = replace(var.domain, "/\\.?$/", ".")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "a" {
  for_each = {
    for a in local.cloudfront_aliases :
    a.name == "" ? "a_root" : "a_${trimsuffix(a.name, ".")}" => a
  }

  name    = join("", [each.value.name, var.domain])
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = each.value.alias_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "aaaa" {
  for_each = {
    for aaaa in local.cloudfront_aliases :
    aaaa.name == "" ? "aaaa_root" : "aaaa_${trimsuffix(aaaa.name, ".")}" => aaaa
  }

  name    = join("", [each.value.name, var.domain])
  type    = "AAAA"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = each.value.alias_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "record" {
  for_each = { for n in flatten([
    for entry in flatten([local.records, var.prod_records]) : [
      for r in entry.record_set : {
        type    = entry.type,
        name    = r.name,
        ttl     = r.ttl,
        records = r.records
      }
    ]
  ]) : n.name == "" ? "${n.type}_main" : "${n.type}_${trimsuffix(n.name, ".")}" => n }

  name    = join("", [each.value.name, var.domain])
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
  zone_id = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "acme_partners" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "partners.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.acme_partners_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}
