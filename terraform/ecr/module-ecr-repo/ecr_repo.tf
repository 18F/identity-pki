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
      "ecr:BatchImportUpstreamImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}

# Dynamically construct our lifecycle rules based on settings
locals {
  // Check for the existence of 'images' and 'days' keys
  has_images = contains(keys(var.lifecycle_policy_settings), "images")
  has_days   = contains(keys(var.lifecycle_policy_settings), "days")

  // Dynamically create the rules array
  rules = concat(
    // If 'images' exists, create its corresponding rule
    local.has_images ? [
      {
        rulePriority = 1
        description  = "Expire all but ${var.lifecycle_policy_settings["images"]} newest images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_policy_settings["images"]
        }
        action = {
          type = "expire"
        }
      }
    ] : [],

    // If 'days' exists, create its corresponding rule. Adjust rulePriority based on the existence of 'images'
    local.has_days ? [
      {
        rulePriority = local.has_images ? 2 : 1
        description  = "Expire images more than ${var.lifecycle_policy_settings["days"]} days old"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_policy_settings["days"]
        }
        action = {
          type = "expire"
        }
      }
    ] : []
  )
}


resource "aws_ecr_lifecycle_policy" "ecr_repo" {
  count      = var.lifecycle_policies_enabled ? 1 : 0
  repository = aws_ecr_repository.ecr_repo.name

  # Need the replace otherwise jsonencode converts all the numbers to strings forcing replacement
  policy = replace(
    jsonencode({
      rules = local.rules
    }),
    "/\"([0-9]+\\.?[0-9]*)\"/", "$1"
  )
}
