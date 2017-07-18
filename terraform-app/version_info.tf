module "version_info" {
    source = "../terraform-modules/version_info"
}

provider "aws" {
    region                 = "${var.version_info_region}"
    alias                  = "version_info"
}

resource "aws_s3_bucket_object" "version_info" {
    provider               = "aws.version_info"
    key                    = "terraform-app/version_info/${var.env_name}.txt"
    bucket                 = "${var.version_info_bucket}"
    content                = <<EOF
commit=${module.version_info.version_info["commit"]}
branch=${module.version_info.version_info["branch"]}
tags=${module.version_info.version_info["tags"]}
version=${trimspace(file("${path.module}/../VERSION.txt"))}
EOF
}
