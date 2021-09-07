
resource "aws_ebs_volume" "gitaly" {
  # XXX gitlab only can live in 2a because of this.
  availability_zone = "us-west-2a"
  size              = 200
  encrypted         = true

  tags = {
    Name = "${var.name}-gitaly-${var.env_name}"
  }
}

output "gitaly_volume_id" {
  value = aws_ebs_volume.gitaly.id
}
