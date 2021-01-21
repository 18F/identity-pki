variable "vpc_cidr" {
  description = "cidr block used by the VPC"
  default = "10.0.0.0/16"
}

variable "region" {
  description = "AWS region, used for S3 bucket names"
}

output "auto_tf_vpc_id" {
  value = aws_vpc.auto_terraform.id
}

output "auto_tf_subnet1_id" {
  value = aws_subnet.auto_terraform1.id
}

output "auto_tf_subnet2_id" {
  value = aws_subnet.auto_terraform2.id
}

output "auto_tf_role_arn" {
  value = aws_iam_role.auto_terraform.arn
}

output "auto_tf_sg_id" {
  value = aws_security_group.auto_terraform.id
}

output "auto_tf_pipeline_role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}

output "auto_tf_bucket_id" {
  value = aws_s3_bucket.codepipeline_bucket.id
}