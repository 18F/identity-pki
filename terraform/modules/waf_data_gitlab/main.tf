data "aws_vpc" "default" {
  tags = {
    "Name" = "${var.vpc_name}"
  }
}

data "github_ip_ranges" "meta" {}

output "gitlab_restricted_paths" {
  value = [
    "^/api.*",
    "^/admin.*",
  ]
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
}

output "gitlab_privileged_ips" {
  value = sort(
    concat(
      local.nat_cidr_blocks,
      [data.aws_vpc.default.cidr_block],
      data.github_ip_ranges.meta.hooks_ipv4,
      ["159.142.0.0/16", ] # GSA VPN IPs
    )
  )
}
