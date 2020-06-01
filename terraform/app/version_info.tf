module "version_info_main" {
  source = "../modules/version_info"
}

# This module expects to find the private configuration checked out in a separate
# repository located (from the root of this repo) at ../{repo-name}-private/.
module "version_info_private" {
  source = "../modules/version_info"
  version_info_path = "${path.module}/../../../identity-devops-private/"
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
main_commit=${module.version_info_main.version_info["commit"]}
main_branch=${module.version_info_main.version_info["branch"]}
main_version=${trimspace(file("${path.module}/../../VERSION.txt"))}
private_commit=${module.version_info_private.version_info["commit"]}
private_branch=${module.version_info_private.version_info["branch"]}
EOF

}

