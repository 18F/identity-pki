resource "aws_ecr_repository" "repository" {
  for_each             = toset(var.ecr_repo_names)
  name                 = "${var.cluster_name}/${each.value}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}