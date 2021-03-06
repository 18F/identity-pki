variable "vpc_cidr" {
  description = "cidr block used by the VPC"
  default = "10.65.0.0/16"
}

variable "auto_tf_fw_subnet_cidr" {
  description = "cidr block used by the network firewall"
  default = "10.65.1.0/24"
}

variable "auto_tf_public_subnet_cidr" {
  description = "cidr block used by the subnet that talks to the world"
  default = "10.65.3.0/24"
}

variable "auto_tf_private_subnet_cidr" {
  description = "cidr block used by the auto_terraform system to do terraform runs"
  default = "10.65.6.0/24"
}

variable "region" {
  description = "AWS region, used for S3 bucket names"
}

output "auto_tf_vpc_id" {
  value = aws_vpc.auto_terraform.id
}

output "auto_tf_subnet_id" {
  value = aws_subnet.auto_terraform_private.id
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