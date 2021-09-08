
resource "aws_ebs_volume" "gitaly" {
  # XXX gitlab only can live in one AZ because of the EBS volume.
  availability_zone = var.gitlab_az
  size              = 200
  encrypted         = true

  tags = {
    Name = "${var.name}-gitaly-${var.env_name}"
  }
}

output "gitaly_volume_id" {
  value = aws_ebs_volume.gitaly.id
}
