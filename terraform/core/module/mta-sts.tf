# MTA-STS policy website and DNS records

# You may ask yourself "Why do we need to serve a static site?"
# Read: https://tools.ietf.org/rfc/rfc8461.txt to find out.

# Create a TLS certificate with ACM
module "acm-cert-mta-sts-cdn" {
  #source = "../../../../identity-terraform//acm_certificate"
  source = "github.com/18F/identity-terraform//acm_certificate?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"
  providers = {
    aws = aws.use1
  }

  domain_name        = "mta-sts.${var.root_domain}"
  validation_zone_id = module.common_dns.primary_zone_id
}

locals {
  mta_sts_mx_block         = join("\n", [for v in module.common_dns.primary_domain_mx_servers : "mx: ${v}"])
  mta_sts_policy           = <<EOF
version: STSv1
mode: ${var.mta_sts_mode}
${local.mta_sts_mx_block}
max_age: ${var.mta_sts_max_age}
EOF
  mta_sts_policy_md5       = md5(local.mta_sts_policy)
  mta_sts_report_addresses = join(",", [for v in var.mta_sts_report_mailboxes : "mailto:${v}"])
}

resource "aws_s3_bucket_object" "mta_sts_txt_file" {
  bucket = aws_s3_bucket.account_static_bucket.id
  key    = "mta-sts/.well-known/mta-sts.txt"
  # Contents of .well-known/mta-sts.txt must follow https://tools.ietf.org/html/rfc8461#section-3.2
  content      = local.mta_sts_policy
  content_type = "text/plain"
  # 15 minute cache TTL
  cache_control = "max-age=900"
}

resource "aws_cloudfront_distribution" "mta_sts_cdn" {
  depends_on = [
    aws_s3_bucket.account_static_bucket,
    module.acm-cert-mta-sts-cdn.finished_id
  ]

  origin {
    domain_name = aws_s3_bucket.account_static_bucket.bucket_regional_domain_name
    origin_id   = "static-mta-sts-${var.root_domain}"
    # Serve from /mta-sts subdirectory in bucket
    origin_path = "/mta-sts"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  aliases         = ["mta-sts.${var.root_domain}"]

  # Throwaway default
  default_root_object = "/index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "static-mta-sts-${var.root_domain}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    viewer_protocol_policy = "https-only"
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn = module.acm-cert-mta-sts-cdn.cert_arn
    # TLS version should align with idp-alg setting
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }

  # Allow access from anywhere
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
    prefix          = "${var.root_domain}/cloudfront/"
  }

  # Serve from US/Canada/Europe CloudFront instances
  price_class = "PriceClass_100"
}

resource "aws_route53_record" "cname_cloudfront_mta_sts" {
  name    = "mta-sts.${var.root_domain}"
  records = [aws_cloudfront_distribution.mta_sts_cdn.domain_name]
  ttl     = "300"
  type    = "CNAME"
  zone_id = module.common_dns.primary_zone_id
}

resource "aws_route53_record" "txt_mta_sts" {
  name    = "_mta-sts.${var.root_domain}"
  ttl     = "300"
  type    = "TXT"
  records = ["v=STSv1; id=${local.mta_sts_policy_md5}"]
  zone_id = module.common_dns.primary_zone_id
}

resource "aws_route53_record" "txt_smtp_tls" {
  name    = "_smtp._tls.${var.root_domain}"
  ttl     = "300"
  type    = "TXT"
  records = ["v=TLSRPTv1;rua=${local.mta_sts_report_addresses}"]
  zone_id = module.common_dns.primary_zone_id
}
