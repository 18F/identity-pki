resource "aws_route53_record" "app_internal" {
  count   = var.apps_enabled
  name    = "app.login.gov.internal"
  zone_id = aws_route53_zone.internal.zone_id
  records = [aws_alb.app[count.index].dns_name]
  ttl     = "300"
  type    = "CNAME"
}

resource "aws_route53_record" "app_external" {
  count   = var.apps_enabled
  name    = "app.${var.env_name}.${var.root_domain}"
  zone_id = var.route53_id
  records = [aws_alb.app[count.index].dns_name]
  ttl     = "300"
  type    = "CNAME"
}

resource "aws_route53_record" "c_dash" {
  count   = var.apps_enabled
  name    = "dashboard.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp" {
  count   = var.apps_enabled
  name    = "sp.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_oidc_sinatra" {
  count   = var.apps_enabled
  name    = "sp-oidc-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_rails" {
  count   = var.apps_enabled
  name    = "sp-rails.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_sinatra" {
  count   = var.apps_enabled
  name    = "sp-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}
