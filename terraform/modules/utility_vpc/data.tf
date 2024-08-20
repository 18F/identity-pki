data "aws_region" "current" {}

data "aws_eip" "main" {
  public_ip = var.image_build_nat_eip
}
