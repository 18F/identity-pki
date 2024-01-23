# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_caller_identity" "current" {}

# Grab the hosted zone ID for our domain
data "aws_route53_zone" "selected" {
  name = var.dnszone
}
data "aws_route53_zone" "pivcac" {
  name = var.pivcac_dnszone
}