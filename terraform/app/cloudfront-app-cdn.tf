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
    module.acm-cert-apps-combined.finished_id,
    aws_cloudfront_function.block_cloudfront_host_header
  ]

  http_version = var.cloudfront_http_version

  origin {
    # Using regional S3 name here per:
    #  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html#concept_S3Origin
    domain_name = module.app_static_bucket_uw2[0].bucket_regional_domain_name
    origin_id   = "static-app-${var.env_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }


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

  default_root_object = var.enable_app_cloudfront_maintenance_page ? "maintenance/maintenance.html" : ""

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "dynamic-app-${var.env_name}"

    cache_policy_id            = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.idp_origin.id
    response_headers_policy_id = var.enable_app_cloudfront_maintenance_page ? data.aws_cloudfront_response_headers_policy.maintenance_response_headers_policy.id : ""


    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.block_cloudfront_host_header.arn
    }

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

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = var.cloudfront_custom_error_responses
    content {
      error_caching_min_ttl = custom_error_response.value.ttl
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = var.enable_app_cloudfront_maintenance_page ? "/maintenance/maintenance.html" : custom_error_response.value.response_page_path
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

  # Cache behavior for static resources coming from s3 origin
  # Makes a cache behavior for each path in var.cloudfront_s3_cache_path
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_app_s3_cache_paths
    content {
      path_pattern     = ordered_cache_behavior.value.path
      allowed_methods  = ["HEAD", "GET"]
      cached_methods   = ["HEAD", "GET"]
      target_origin_id = "static-app-${var.env_name}"

      cache_policy_id            = ordered_cache_behavior.value.caching_enabled ? data.aws_cloudfront_cache_policy.managed_caching_optimized.id : data.aws_cloudfront_cache_policy.managed_caching_disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.managed_cors_s3origin.id
      response_headers_policy_id = var.enable_cloudfront_maintenance_page ? data.aws_cloudfront_response_headers_policy.maintenance_response_headers_policy.id : ""

      min_ttl                = 0
      viewer_protocol_policy = "https-only"
      compress               = true
    }
  }


}




