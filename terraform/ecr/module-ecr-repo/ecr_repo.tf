resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = var.ecr_repo_tag_mutability
  tags                 = var.tags
  encryption_type      = var.encryption_type
  kms_key              = var.kms_key
}
