data "aws_vpc" "default" {
  tags = {
    "Name" = "${var.vpc_name}"
  }
}

data "github_ip_ranges" "meta" {}

output "restricted_paths" {
  value = {
    paths = [
      "^/api.*",
      "^/admin.*",
    ]
    exclusions = [
      "^/api/graphql.*",
    ]
  }
}

data "aws_nat_gateways" "ngws" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_nat_gateway" "ngw" {
  count = length(data.aws_nat_gateways.ngws.ids)
  id    = tolist(data.aws_nat_gateways.ngws.ids)[count.index]
}

locals {
  nat_cidr_blocks = formatlist("%s/32", [for ngw in data.aws_nat_gateway.ngw : ngw.public_ip])
  vpc_cidr_blocks = [for entry in data.aws_vpc.default.cidr_block_associations : entry.cidr_block]
}

output "privileged_cidrs_v4" {
  value = sort(
    concat(
      local.nat_cidr_blocks,
      local.vpc_cidr_blocks,
      var.privileged_cidr_blocks_v4,
      data.github_ip_ranges.meta.hooks_ipv4,
    )
  )
}

output "us_regions" {
  value = [
    "AS",
    "GU",
    "MP",
    "PR",
    "UM",
    "US",
    "VI",
  ]
}
