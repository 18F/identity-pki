variable "env" { description = "Environment (prod/qa/dev)" }
variable "role" { description = "Host role (idp/jumphost/etc)" }
variable "domain" { description = "Second level domain, e.g. login.gov" }
variable "chef_download_url" { description = "URL to download chef debian package" }
variable "chef_download_sha256" {
    description = "Expected SHA256 checksum of chef debian package"
    default = ""
}

variable "private_s3_ssh_key_url" {
    description = "S3 URL to use to download SSH key used to clone the private_git_clone_url"
}
variable "private_git_clone_url" {
    description = "Git SSH URL used to clone identity-devops-private"
}
variable "private_git_ref" {
    description = "Git ref to check out after cloning private_git_clone_url"
    default = "HEAD"
}

variable "main_s3_ssh_key_url" {
    description = "S3 URL to use to download SSH key used to clone the main_git_clone_url"
}
variable "main_git_clone_url" {
    description = "Git SSH URL used to clone identity-devops"
}
variable "main_git_ref" {
    description = "Git ref to check out after cloning main_git_clone_url"
    default = "HEAD"
}

# Ideally this module would have contained the aws_launch_configuration since
# it looks pretty much the same across auto scaling groups.
# But this was not possible due to a terraform bug:
# https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See ./vestigial.tf.txt for config that may be useful to implement this if the
# terraform bug is ever fixed.

# The output of this module is a rendered cloud-init user data script,
# appropriate for including in an aws_launch_configuration resource.
output "rendered_cloudinit_config" {
    value = "${data.template_cloudinit_config.bootstrap.rendered}"
}

data "template_file" "set-hostname" {
    template = "${file("${path.module}/cloud-init.hostname.yaml.tpl")}"
    vars {
        hostname_prefix = "${var.role}"
        domain = "${var.env}.${var.domain}"
    }
}

data "template_file" "cloud-init-main" {
    template = "${file("${path.module}/cloud-init.main.yaml.tpl")}"
    vars {
        chef_download_sha256 = "${var.chef_download_sha256}"
        chef_download_url = "${var.chef_download_url}"

        domain = "${var.domain}"
        env = "${var.env}"
        role = "${var.role}"

        private_git_clone_url = "${var.private_git_clone_url}"
        private_git_ref = "${var.private_git_ref}"
        private_s3_ssh_key_url = "${var.private_s3_ssh_key_url}"

        main_git_clone_url = "${var.main_git_clone_url}"
        main_git_ref = "${var.main_git_ref}"
        main_s3_ssh_key_url = "${var.main_s3_ssh_key_url}"
    }
}

data "template_cloudinit_config" "bootstrap" {
    # may need to change these to true if we hit 16K in size
    gzip = false
    base64_encode = false

    part {
        filename = "set-hostname.yaml"
        content_type = "text/cloud-config"
        content = "${data.template_file.set-hostname.rendered}"
    }

    part {
        filename = "provision.sh"
        content_type = "text/x-shellscript"
        content = "${file("${path.module}/provision.sh")}"
    }

    part {
        filename = "main.yaml"
        content_type = "text/cloud-config"
        content = "${data.template_file.cloud-init-main.rendered}"
    }
}
