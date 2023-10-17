# block requests with cloudfront.net in host header (DNSSEC requirement)
# https://repost.aws/knowledge-center/cloudfront-comply-dnssec
resource "aws_cloudfront_function" "block_cloudfront_host_header" {
  name    = "${var.env_name}-block-cloudfront-host-header"
  runtime = "cloudfront-js-1.0"
  comment = "Block requests with Host header value ending with cloudfront.net"
  publish = true
  code    = <<EOF
function handler(event) {
  var request = event.request;

    // Extract the host header value
    var host = request.headers.host.value;

    // Check if the host header value ends with "cloudfront.net"
    if (host.endsWith('cloudfront.net')) {
      // Return a response to block the request
      return {
        statusCode: 403,
        statusDescription: 'Forbidden',
        headers: {
          'content-type': {
            value: 'text/plain'
          }
        },
        body: 'Access to this resource is forbidden.'
      };
    }

    // Allow the request to proceed
    return request;
  }
EOF
}
