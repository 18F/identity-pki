resource "aws_vpc" "main" {
  cidr_block                       = var.image_build_vpc_cidr
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = {
    Name = "${var.name}-${data.aws_region.current.name}-${var.account_name}-imagebuild"
  }
}