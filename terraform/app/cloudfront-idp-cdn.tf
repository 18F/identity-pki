data "aws_sns_topic" "cloudfront_alarm" {
  name = "devops_high_priority"
}

# Create a TLS certificate with ACM
module "acm-cert-idp-static-cdn" {
  count  = var.enable_idp_cdn ? 1 : 0
  source = "github.com/18F/identity-terraform//acm_certificate?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  #source = "../../../identity-terraform/acm_certificate"
  providers = {
    aws = aws.use1
  }

  domain_name        = "static.${local.idp_domain_name}"
  validation_zone_id = var.route53_id
}

resource "aws_cloudfront_distribution" "idp_static_cdn" {
  count = var.enable_idp_cdn ? 1 : 0

  depends_on = [
    aws_s3_bucket.idp_static_bucket[0],
    module.acm-cert-idp-static-cdn[0].finished_id
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
  aliases         = ["static.${local.idp_domain_name}"]

  # Throwaway default
  default_root_object = "/index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "static-idp-${var.env_name}"

    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3origin.id

    min_ttl                = 0
    viewer_protocol_policy = "https-only"
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn = module.acm-cert-idp-static-cdn[0].cert_arn
    # TLS version should align with idp-alg setting
    minimum_protocol_version = "TLSv1.2_2018"
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

module "cloudfront_idp_cdn_alarms" {
  count  = var.cdn_idp_static_assets_cloudwatch_alarms_enabled
  source = "../modules/cloudfront_cdn_alarms"

  providers = {
    aws = aws.use1
  }
  alarm_actions = local.low_priority_alarm_actions_use1
  dimensions = {
    DistributionId = aws_cloudfront_distribution.idp_static_cdn[count.index].id
    Region         = "Global"
  }
  threshold         = var.cdn_idp_static_assets_alert_threshold
  distribution_name = "IDP Static Assets"
  env_name          = var.env_name
}
