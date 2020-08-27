# Create a TLS certificate with ACM
module "acm-cert-idp-static-cdn" {
  source = "github.com/18F/identity-terraform//acm_certificate?ref=cae8dcdaf37e9e423480561de27ccfa1e882b5ea"
  providers = {
    aws = aws.use1
  }
  enabled            = var.enable_idp_cdn ? 1 : 0
  domain_name        = "static.${local.idp_domain_name}"
  validation_zone_id = var.route53_id
}

resource "aws_cloudfront_distribution" "idp_static_cdn" {
  count = var.enable_idp_cdn ? 1 : 0

  depends_on = [
    aws_s3_bucket.idp_static_bucket[0],
    module.acm-cert-idp-static-cdn.finished_id
  ]

  origin {
    # Using regional S3 name here per:
    #  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html#concept_S3Origin
    domain_name = aws_s3_bucket.idp_static_bucket[0].bucket_regional_domain_name
    origin_id   = "static-idp-${var.env_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  aliases         = list("static.${local.idp_domain_name}")

  # Throwaway default
  default_root_object = "/index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "static-idp-${var.env_name}"

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
    acm_certificate_arn      = module.acm-cert-idp-static-cdn.cert_arn
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
    prefix          = "${var.env_name}/cloudfront/"
  }

  # Serve from US/Canada/Europe CloudFront instances
  price_class = "PriceClass_100"
}

resource "aws_route53_record" "cname_cloudfront_idp" {
  count   = var.enable_idp_cdn ? 1 : 0
  name    = "static.${local.idp_domain_name}"
  records = [aws_cloudfront_distribution.idp_static_cdn[count.index].domain_name]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}
