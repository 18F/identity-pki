
module "firewall" {
  source = "../modules/firewall/"

  az_zones                                   = var.az_zones
  firewall_cidr_blocks                       = var.firewall_cidr_blocks
  eip_allocation_blocks                      = var.eip_allocation_blocks
  nat_cidr_blocks                            = var.nat_cidr_blocks
  firewall_cidr_block_aza                    = var.firewall_cidr_block_aza
  nat_cidr_block_aza                         = var.nat_cidr_block_aza
  firewall_cidr_block_azb                    = var.firewall_cidr_block_azb
  nat_cidr_block_azb                         = var.nat_cidr_block_azb
  target_types                               = var.target_types
  rules_type                                 = var.rules_type
  env_name                                   = var.env_name
  slack_events_sns_hook_arn                  = var.slack_events_sns_hook_arn
  vpc_id                                     = aws_vpc.default.id
  name                                       = var.name
  nat_subnet_id_usw2a                        = aws_subnet.nat["us-west-2a"].id
  nat_subnet_id_usw2b                        = aws_subnet.nat["us-west-2b"].id
  gateway_id                                 = aws_internet_gateway.default.id 
  validdomainfile                            = var.validdomainfile
}
