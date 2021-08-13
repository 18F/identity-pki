# Create a TLS certificate with ACM
module "acm-cert-public-reporting-data-cdn" {
  source = "github.com/18F/identity-terraform//acm_certificate?ref=21a2ce16cf1dbf85822c9005d72f8d17cb9dbe4b"
  providers = {
    aws = aws.use1
  }

  domain_name        = "public-reporting-data.${var.env_name}.${var.root_domain}"
  validation_zone_id = var.route53_id
}

resource "aws_cloudfront_distribution" "public_reporting_data_cdn" {

  depends_on = [
    aws_s3_bucket.public_reporting_data,
    module.acm-cert-public-reporting-data-cdn.finished_id
  ]

  origin {
    domain_name = aws_s3_bucket.public_reporting_data.bucket_regional_domain_name
    origin_id   = "public-reporting-data-${var.env_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  aliases         = list("public-reporting-data.${var.env_name}.${var.root_domain}")

  # Throwaway default
  default_root_object = "/index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "public-reporting-data-${var.env_name}"

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
    acm_certificate_arn      = module.acm-cert-public-reporting-data-cdn.cert_arn
    minimum_protocol_version = "TLSv1.2"
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

resource "aws_route53_record" "public_reporting_data_a" {
  zone_id = var.route53_id
  name    = "public-reporting-data.${var.env_name}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.public_reporting_data_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.public_reporting_data_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "public_reporting_data_aaaa" {
  zone_id = var.route53_id
  name    = "public-reporting-data.${var.env_name}.${var.root_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.public_reporting_data_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.public_reporting_data_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_metric_alarm" "public_reporting_data_cloudfront_alert" {
  alarm_name          = "Public Reporting Data CloudFront ${var.env_name} 4xx Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This Alarm is executed when 4xx errors appear on the CF Distribution"
  alarm_actions       = [data.aws_sns_topic.cloudfront_alarm.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.public_reporting_data_cdn.id
  }
}

