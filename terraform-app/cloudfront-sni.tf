resource "aws_cloudfront_distribution" "sni_profiling" {
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    domain_name = "${var.env_name == "prod" ? "snitestsecure.${var.root_domain}" : "snitest.${var.env_name}.${var.root_domain}"}"
    origin_id   = "${var.env_name}.snitest"
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "favicon-16x16.png"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "${var.env_name}.snitest"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    viewer_protocol_policy = "https-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "vip"
  }
}
