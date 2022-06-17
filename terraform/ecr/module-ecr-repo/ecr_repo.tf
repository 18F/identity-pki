resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = var.ecr_repo_tag_mutability
  tags                 = var.tags

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key
  }
}

resource "aws_ecr_repository_policy" "ecr_repo" {
  repository = aws_ecr_repository.ecr_repo.name
  policy     = data.aws_iam_policy_document.ecr_repo.json
}

locals {
  readonlyrootaccounts = formatlist("arn:aws:iam::%s:root", var.readonly_accountids)
}

data "aws_iam_policy_document" "ecr_repo" {
  statement {
    sid = "Allow Prod Replication"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.prod_accountid}:root"]
    }
    actions = [
      "ecr:CreateRepository",
      "ecr:ReplicateImage"
    ]
  }

  statement {
    sid = "Allow Readonly access to runners"
    principals {
      type        = "AWS"
      identifiers = local.readonlyrootaccounts
    }
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
