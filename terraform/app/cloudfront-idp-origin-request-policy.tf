resource "aws_cloudfront_origin_request_policy" "idp_origin" {
  name    = "idp-origin-${var.env_name}"
  comment = "Origin request policy for idp in ${var.env_name}"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}
