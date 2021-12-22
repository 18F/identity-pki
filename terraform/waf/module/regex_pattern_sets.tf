resource "aws_wafv2_regex_pattern_set" "relaxed_uri_paths" {
  name        = "${var.env}-relaxed-uri-paths"
  description = "Paths to excempt from false positive happy SQLi and other rules"
  scope       = "REGIONAL"

  dynamic "regular_expression" {
    for_each = var.relaxed_uri_paths

    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    environment = var.env
  }
}
