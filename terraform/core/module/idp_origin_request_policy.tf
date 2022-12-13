# Moving this from terraform/app because of a hard limit of 20
# per account which we quickly ran into. Limit is mentioned
# https://docs.amazonaws.cn/en_us/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html
# This is now a shared origin request policy across the entire
# account.
resource "aws_cloudfront_origin_request_policy" "idp_origin" {
  provider = aws.use1
  name    = "idp-origin-request-policy"
  comment = "Origin request policy for all IDP servers"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewerAndWhitelistCloudFront"
    # Logged by NGINX and CloudFront-Viewer-Address used by IdP to get source port
    headers {
      items = [
        "CloudFront-Viewer-Address",
        "CloudFront-Viewer-Http-Version",
        "CloudFront-Viewer-TLS",
        "CloudFront-Viewer-Country",
        "CloudFront-Viewer-Country-Region",
      ]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}
