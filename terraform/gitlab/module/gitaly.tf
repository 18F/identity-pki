
resource "aws_ebs_volume" "gitaly" {
  # XXX gitlab only can live in one AZ because of the EBS volume.
  availability_zone = var.gitlab_az
  size              = 200
  encrypted         = true

  tags = {
    Name = "${var.name}-gitaly-${var.env_name}"
  }
}

resource "aws_s3_bucket_object" "gitaly_volume_id" {
  bucket  = data.aws_s3_bucket.secrets.id
  key     = "${var.env_name}/gitaly_ebs_volume"
  content = aws_ebs_volume.gitaly.id

  source_hash = md5(aws_ebs_volume.gitaly.id)
}
