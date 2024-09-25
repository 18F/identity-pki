data "aws_region" "current" {}

data "aws_ip_ranges" "ec2" {
  regions  = [data.aws_region.current.name]
  services = ["ec2"]
}
