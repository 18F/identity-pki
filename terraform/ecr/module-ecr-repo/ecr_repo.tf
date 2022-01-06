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
  policy     = <<-EOF
{
  "Version": "2008-10-17",
  "Statement": [
      {
          "Sid": "Default Account Allow",
          "Effect": "Allow",
          "Principal": { "AWS": "${data.aws_caller_identity.current.account_id}" },
          "Action": "*"
      },
      {
          "Sid":"Allow Prod Replication",
          "Effect":"Allow",
          "Principal":{ "AWS": "555546682965" },
          "Action":[
              "ecr:CreateRepository",
              "ecr:ReplicateImage"
          ],
          "Resource": [
              "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repo_name}"
          ]
      }
  ]
}
EOF
}
