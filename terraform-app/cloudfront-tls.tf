data "aws_acm_certificate" "tlstest" {
    # tlstest.secure.login.gov in prod, tltest.$env.login.gov in other environments
    domain = "${var.env_name == "prod" ? "tlstest.secure.${var.root_domain}" : "tlstest.${var.env_name}.${var.root_domain}"}"
    statuses = ["ISSUED"]
    provider = "aws.use1"
}

resource "aws_cloudfront_distribution" "tls_profiling" {
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    domain_name = "${var.env_name == "prod" ? "secure.${var.root_domain}" : "idp.${var.env_name}.${var.root_domain}"}"
    origin_id   = "${var.env_name}.tlstest"
  }

  aliases = ["${var.env_name == "prod" ? "tlstest.secure.${var.root_domain}" : "tlstest.${var.env_name}.${var.root_domain}"}"]
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "favicon-16x16.png"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "${var.env_name}.tlstest"

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
    acm_certificate_arn      = "${data.aws_acm_certificate.tlstest.arn}"
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}
