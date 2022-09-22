resource "aws_wafv2_regex_pattern_set" "relaxed_uri_paths" {
  name        = "${var.env}-relaxed-uri-paths"
  description = "Paths to excempt from false positive happy SQLi and other rules"
  scope       = var.wafv2_web_acl_scope

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

resource "aws_wafv2_regex_pattern_set" "header_blocks" {
  count       = length(var.header_block_regex)
  name        = "${var.env}-header-${var.header_block_regex[count.index].field_name}-blocks"
  description = "Regex patterns to block related to header ${var.header_block_regex[count.index].field_name}"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = var.header_block_regex[count.index].patterns
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_regex_pattern_set" "query_string_blocks" {
  count       = length(var.query_block_regex) >= 1 ? 1 : 0
  name        = "${var.env}-${var.app}-query-string-blocks"
  description = "Regex patterns in query strings to block"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = var.query_block_regex
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_regex_pattern_set" "restricted_paths" {
  count       = length(var.restricted_paths.paths) > 0 ? 1 : 0
  name        = "${var.env}-${var.app}-restricted-paths"
  description = "Regex patterns of paths to restrict to VPN and VPC"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = toset(var.restricted_paths.paths)
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_regex_pattern_set" "restricted_paths_exclusions" {
  count       = length(var.restricted_paths.exclusions) > 0 ? 1 : 0
  name        = "${var.env}-${var.app}-restricted-paths-exclusions"
  description = "Regex patterns of paths NOT to restrict to VPN and VPC"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = toset(var.restricted_paths.exclusions)
    content {
      regex_string = regular_expression.value
    }
  }

  tags = {
    environment = var.env
  }
}
