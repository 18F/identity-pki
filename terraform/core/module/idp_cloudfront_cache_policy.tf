# The Managed-CORS-S3Origin policy passes the Origin, Access-Control-Request-Headers,
# Access-Control-Request-Method headers to the S3 bucket. We previously used the
# CloudFront Managed-CachingOptimized caching policy, but this caused issues because
# the policy does not take into account the headers when building the cache key.
# This led to situations where if the first request for an object came w/the header
# "Origin: https://example.com", S3 would respond with "Access-Control-Allow-Origin:
# https://example.com". If later requests came from "Origin: https://example2.com",
# CloudFront would respond with "Access-Control-Allow-Origin: https://example.com"
# and the browser would block the request due to a CORS origin mismatch.
#
# Our solution: a CloudFront cache policy that includes the headers in the cache key.
# This ensures requests with different "Origin" headers have separate cache keys.
#
# "Origin" is difficult to search for since it is overloaded in the context of
# talking about CORS and CloudFront. It can refer to either the HTTP header or the
# CloudFront origin (S3 in this case).
#
# This is configured at the account level (vs. app environment level) as there is a
# quota/limit of 20 cache policies per account, which cannot be increased.
resource "aws_cloudfront_cache_policy" "public_reporting_data_cache_policy" {
  name        = "Public-Reporting-Data-Cache-Policy"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers"
        ]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
