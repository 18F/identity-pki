resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "${var.name}-${var.account_name}-imagebuild"
  }
}