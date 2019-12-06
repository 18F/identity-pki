module "main_to_analytics_peering" {
  source = "../terraform-modules/analytics_peering_main/"

  enabled = var.analytics_vpc_peering_enabled

  analytics_cidr_block = var.analytics_cidr_block
  analytics_vpc_id     = var.analytics_vpc_id
  main_vpc_id          = aws_vpc.default.id
  main_route_table_id  = aws_vpc.default.main_route_table_id
}

