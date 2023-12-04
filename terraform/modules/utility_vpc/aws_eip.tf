resource "aws_eip" "main" {
  associate_with_private_ip = var.image_build_nat_eip
}