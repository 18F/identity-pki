module "acm-cert-app-static-cdn" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//acm_certificate?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/acm_certificate"
  providers = {
    aws = aws.use1
  }

  domain_name               = local.app_domain_name
  subject_alternative_names = compact(flatten(local.app_alternative_names))
  validation_zone_id        = var.route53_id
}

resource "aws_cloudfront_distribution" "app_cdn" {
  count = var.apps_enabled
  depends_on = [
    module.acm-cert-apps-combined.finished_id
  ]

  http_version = var.cloudfront_http_version

  origin {
    domain_name = aws_alb.app[0].dns_name
    origin_id   = "dynamic-app-${var.env_name}"
    custom_header {
      name  = local.cloudfront_security_header.name
      value = local.cloudfront_security_header.value[0]
    }
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_read_timeout    = var.cloudfront_read_timeout
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  web_acl_id = var.app_cloudfront_waf_enabled ? (
  data.aws_wafv2_web_acl.cloudfront_web_acl[0].arn) : ""

  enabled         = true
  is_ipv6_enabled = true
  aliases         = compact(flatten([local.app_domain_name, local.app_alternative_names]))

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "dynamic-app-${var.env_name}"

    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.idp_origin.id

    min_ttl                = 0
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm-cert-app-static-cdn[0].cert_arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Log to ELB log bucket to keep front end AWS logs together.
  # CloudFront logs are batched and may take over 24 hours to appear.
  logging_config {
    bucket          = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}.s3.amazonaws.com"
    include_cookies = false
    prefix          = "${var.env_name}/cloudfront/"
  }

  price_class = "PriceClass_100"
}




