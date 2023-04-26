# get account name and list of VPCs identified with fisma tag

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

module "waf_sets_regional" {
  source = "../../modules/waf_sets/"

  privileged_cidr_blocks_v4 = var.privileged_cidr_blocks_v4
  privileged_cidr_blocks_v6 = var.privileged_cidr_blocks_v6

  # Uncomment to use header_block_regex filter
  # Only do once env-specific regex sets are gone!
  #header_block_regex = yamldecode(file("header_block_regex.yml"))
}

module "waf_sets_cloudfront" {
  source = "../../modules/waf_sets/"
  providers = {
    aws = aws.use1
  }

  wafv2_web_acl_scope       = "CLOUDFRONT"
  privileged_cidr_blocks_v4 = module.waf_sets_regional.privileged_cidrs_v4
  privileged_cidr_blocks_v6 = module.waf_sets_regional.privileged_cidrs_v6
  ip_block_cidrs_v4         = module.waf_sets_regional.block_list_v4
  ip_block_cidrs_v6         = module.waf_sets_regional.block_list_v6
  # Uncomment to use header_block_regex filter
  # Only do once env-specific regex sets are gone!
  #header_block_regex = yamldecode(file("header_block_regex.yml"))
}