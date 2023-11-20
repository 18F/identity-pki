# This is configured at the account level (vs. app environment level) as there is a
# quota/limit of 20 cache policies per account, which cannot be increased.
resource "aws_cloudfront_response_headers_policy" "maintenance_response_headers_policy" {
  name    = "Maintenance-Response-Headers-Policy"
  comment = "This policy is used to set security headers and to return an explicit no-store cache-control header"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31556952
      include_subdomains         = true
      preload                    = true
      override                   = false
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = false
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }

    content_type_options {
      override = false
    }
  }

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = false
      value    = "no-store"
    }
  }
}
