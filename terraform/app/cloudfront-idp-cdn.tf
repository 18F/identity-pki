data "aws_sns_topic" "cloudfront_alarm" {
  name = "devops_high_priority"
}

data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "idp_origin" {
  name = "idp-origin-request-policy"
}

data "aws_wafv2_web_acl" "cloudfront_web_acl" {
  provider = aws.use1
  count    = var.idp_cloudfront_waf_enabled ? 1 : 0
#  name     = "${var.env_name}-idp-waf"
  name = "dev-idp-waf"
  scope    = "CLOUDFRONT"
}

resource "random_string" "security_header" {
  length  = 32
  special = false
}

locals {
  # Prevents access directly to origin using a rule on the alb listener
  # Name and random value are arbitrary, can be any string for each
  cloudfront_security_header = {
    name  = "Origin-Access-Control",
    value = [random_string.security_header.result]
  }
}

# Create a TLS certificate with ACM
module "acm-cert-idp-static-cdn" {
  count  = var.enable_idp_cdn ? 1 : 0
  source = "github.com/18F/identity-terraform//acm_certificate?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../identity-terraform/acm_certificate"
  providers = {
    aws = aws.use1
  }

  domain_name               = local.idp_domain_name
  subject_alternative_names = compact(flatten([local.idp_cdn_root, local.idp_origin_name]))
  validation_zone_id        = var.route53_id
}

resource "aws_cloudfront_distribution" "idp_static_cdn" {
  count = var.enable_idp_cdn ? 1 : 0

  depends_on = [
    module.acm-cert-idp[0].finished_id
  ]

  # Maximum http version supported
  http_version = var.cloudfront_http_version

  # Origin for serving static content with s3 bucket as origin
  origin {
    # Using regional S3 name here per:
    #  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html#concept_S3Origin
    domain_name = aws_s3_bucket.idp_static_bucket[0].bucket_regional_domain_name
    origin_id   = "static-idp-${var.env_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  # Origin for serving dynamic content with idp server as origin
  origin {
    domain_name = local.idp_origin_name
    origin_id   = "dynamic-idp-${var.env_name}"
    custom_header {
      name  = local.cloudfront_security_header.name
      value = local.cloudfront_security_header.value[0]
    }
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  web_acl_id = var.idp_cloudfront_waf_enabled ? (
  data.aws_wafv2_web_acl.cloudfront_web_acl[count.index].arn) : ""

  enabled         = true
  is_ipv6_enabled = true
  aliases         = compact(flatten([local.idp_cdn_root, local.idp_origin_name, local.idp_domain_name]))

  default_root_object = var.enable_cloudfront_maintenance_page ? "maintenance/maintenance.html" : ""

  # Cache behavior for static resources coming from s3 origin
  # Makes a cache behavior for each path in var.cloudfront_s3_cache_path
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_s3_cache_paths
    content {
      path_pattern     = ordered_cache_behavior.value.path
      allowed_methods  = ["HEAD", "GET"]
      cached_methods   = ["HEAD", "GET"]
      target_origin_id = "static-idp-${var.env_name}"

      cache_policy_id          = ordered_cache_behavior.value.caching_enabled ? data.aws_cloudfront_cache_policy.managed_caching_optimized.id : data.aws_cloudfront_cache_policy.managed_caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3origin.id

      min_ttl                = 0
      viewer_protocol_policy = "https-only"
      compress               = true
    }
  }

  # Cache behavior for dynamic resources coming from idp origin
  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "dynamic-idp-${var.env_name}"

    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.idp_origin.id

    min_ttl                = 0
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Swapping cert from previous static.${local.idp_origin_name} to the idp cert
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

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = var.cloudfront_custom_error_responses
    content {
      error_caching_min_ttl = custom_error_response.value.ttl
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = var.enable_cloudfront_maintenance_page ? "/maintenance/maintenance.html" : custom_error_response.value.response_page_path
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

# non-prod envs are currently configured to both idp.<env>.identitysandbox.gov
# and <env>.identitysandbox.gov
resource "aws_route53_record" "c_cloudfront_env" {
  count   = var.env_name == "prod" ? 0 : 1
  name    = "${var.env_name}.${var.root_domain}"
  records = var.enable_idp_cdn ? [aws_cloudfront_distribution.idp_static_cdn[0].domain_name] : [aws_alb.idp.dns_name]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

# Swaps the idp.<env>.identitysandbox.gov or secure.login.gov to point at 
# either cloudfront or alb depending on enable_idp_cdn toggle
resource "aws_route53_record" "c_cloudfront_idp" {
  name    = local.idp_domain_name
  records = var.enable_idp_cdn ? [aws_cloudfront_distribution.idp_static_cdn[0].domain_name] : [aws_alb.idp.dns_name]
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
