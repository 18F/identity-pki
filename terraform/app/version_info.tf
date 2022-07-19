locals {
  # This module usually expects to find the private configuration checked out in a separate
  # repository located (from the root of this repo) at ../{repo-name}-private/.
  privatedir = var.privatedir == "" ? "${path.module}/../../../identity-devops-private/" : var.privatedir
}

data "external" "version_info" {
  program = ["bash", "${path.module}/version_info.sh", path.module, local.privatedir]
}

provider "aws" {
  region = var.version_info_region
  alias  = "version_info"
}

resource "aws_s3_object" "version_info" {
  provider = aws.version_info
  key      = "terraform-app/version_info/${var.env_name}.txt"
  bucket   = var.version_info_bucket
  content  = <<EOF
main_commit=${data.external.version_info.result.identity-devops-commit}
main_branch=${data.external.version_info.result.identity-devops-branch}
main_version=${trimspace(file("${path.module}/../../VERSION.txt"))}
private_commit=${data.external.version_info.result.identity-devops-private-commit}
private_branch=${data.external.version_info.result.identity-devops-private-branch}
EOF
}
