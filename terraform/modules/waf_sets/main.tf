terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# get account name and list of VPCs/NGWs identified with fisma tag

data "aws_iam_account_alias" "current" {}

data "aws_vpcs" "default" {
  tags = {
    "fisma" = "${var.fisma_tag}"
  }
}

data "aws_vpc" "default" {
  count = length(data.aws_vpcs.default.ids)
  id    = tolist(data.aws_vpcs.default.ids)[count.index]
}

data "aws_nat_gateways" "ngws" {
  tags = {
    "fisma" = "${var.fisma_tag}"
  }
}

data "aws_nat_gateway" "ngw" {
  count = length(data.aws_nat_gateways.ngws.ids)
  id    = tolist(data.aws_nat_gateways.ngws.ids)[count.index]
}

locals {
  tf_acct      = trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")
  web_acl_name = "${local.tf_acct}-${var.app_name}"

  privileged_cidrs_v4 = sort(compact(concat(
    var.privileged_cidr_blocks_v4,
    formatlist("%s/32", [
      for ngw in data.aws_nat_gateway.ngw : ngw.public_ip
    ]),
    flatten([for vpc in data.aws_vpc.default : [
      for entry in vpc.cidr_block_associations : entry.cidr_block
    ]])))
  )
  # for future expansion
  privileged_cidrs_v6 = sort(compact(concat(
    var.privileged_cidr_blocks_v6,
    [for vpc in data.aws_vpc.default : vpc.ipv6_cidr_block]
  )))
}

# regex pattern sets -- can have a maximum of 10, per account, per region

resource "aws_wafv2_regex_pattern_set" "relaxed_uri_paths" {
  name        = "${local.tf_acct}-relaxed-uri-paths"
  description = "Paths to exempt from false positive happy SQLi and other rules"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = var.relaxed_uri_paths

    content {
      regex_string = regular_expression.value
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "header_blocks" {
  count = length(var.header_block_regex)
  name = join("-", [
    "${local.tf_acct}-header",
    "${var.header_block_regex[count.index].field_name}-blocks"
  ])
  description = join(" ", [
    "Regex patterns to block related to header",
    var.header_block_regex[count.index].field_name
  ])
  scope = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = var.header_block_regex[count.index].patterns
    content {
      regex_string = regular_expression.value
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "restricted_paths" {
  count       = length(var.restricted_paths.paths) > 0 ? 1 : 0
  name        = "${local.tf_acct}-${var.app_name}-restricted-paths"
  description = "Regex patterns of paths to restrict to VPN and VPC"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = toset(var.restricted_paths.paths)
    content {
      regex_string = regular_expression.value
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "restricted_paths_exclusions" {
  count       = length(var.restricted_paths.exclusions) > 0 ? 1 : 0
  name        = "${local.tf_acct}-${var.app_name}-restricted-paths-exclusions"
  description = "Regex patterns of paths NOT to restrict to VPN and VPC"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = toset(var.restricted_paths.exclusions)
    content {
      regex_string = regular_expression.value
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "limit_exempt_paths" {
  name        = "${local.tf_acct}-limit-exempt-paths"
  description = "Paths to exempt from rate-limiting acl rules"
  scope       = var.wafv2_web_acl_scope

  dynamic "regular_expression" {
    for_each = var.limit_exempt_paths

    content {
      regex_string = regular_expression.value
    }
  }
}

# IP sets -- can have a maximum of 100, per account, per region

resource "aws_wafv2_ip_set" "block_list_v4" {
  count = length(var.ip_block_cidrs_v4) > 0 ? 1 : 0

  name               = "${local.web_acl_name}-block-list-v4"
  description        = "${local.web_acl_name} IPv4 Block List"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.ip_block_cidrs_v4
}

resource "aws_wafv2_ip_set" "block_list_v6" {
  count = length(var.ip_block_cidrs_v6) > 0 ? 1 : 0

  name               = "${local.web_acl_name}-block-list-v6"
  description        = "${local.web_acl_name} IPv6 Block List"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV6"
  addresses          = var.ip_block_cidrs_v6
}

resource "aws_wafv2_ip_set" "privileged_ips_v4" {
  count              = length(local.privileged_cidrs_v4) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips-v4"
  description        = "${local.web_acl_name} Privileged IPv4 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = local.privileged_cidrs_v4
}

resource "aws_wafv2_ip_set" "privileged_ips_v6" {
  count              = length(local.privileged_cidrs_v6) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips-v6"
  description        = "${local.web_acl_name} Privileged IPv6 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV6"
  addresses          = local.privileged_cidrs_v6
}
