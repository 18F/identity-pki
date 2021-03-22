
locals {
  # This module expects to find the private configuration checked out in a separate
  # repository located (from the root of this repo) at ../{repo-name}-private/.
  privatedir = "${path.module}/../../../identity-devops-private/"

  # the seds are to turn this into valid json
  commitcmd = "git rev-parse HEAD | sed 's/^/{\"data\":\"/g' | sed 's/$/\"}/g'"
  branchcmd = "git rev-parse --abbrev-ref HEAD | sed 's/^/{\"data\":\"/g' | sed 's/$/\"}/g'"
}

data "external" "main_commit" {
  working_dir = path.module
  program = ["bash", "-c", local.commitcmd]
}

data "external" "main_branch" {
  working_dir = path.module
  program = ["bash", "-c", local.branchcmd]
}

data "external" "private_commit" {
  working_dir = local.privatedir
  program = ["bash", "-c", local.commitcmd]
}

data "external" "private_branch" {
  working_dir = local.privatedir
  program = ["bash", "-c", local.branchcmd]
}

provider "aws" {
  region = var.version_info_region
  alias  = "version_info"
}

resource "aws_s3_bucket_object" "version_info" {
  provider = aws.version_info
  key      = "terraform-app/version_info/${var.env_name}.txt"
  bucket   = var.version_info_bucket
  content  = <<EOF
main_commit=${data.external.main_commit.result.data}
main_branch=${data.external.main_branch.result.data}
main_version=${trimspace(file("${path.module}/../../VERSION.txt"))}
private_commit=${data.external.private_commit.result.data}
private_branch=${data.external.private_branch.result.data}
EOF
}
