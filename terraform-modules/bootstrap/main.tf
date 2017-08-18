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

data "external" "set-hostname-template" {
    program = ["ruby", "${path.module}/erb_template.rb"]

    query = {
        erb_template = "${file("${path.module}/cloud-init.hostname.yaml.erb")}"
        hostname_prefix = "${var.role}"
        domain = "${var.env}.${var.domain}"
    }
}

data "external" "cloud-init-base-template" {
    program = ["ruby", "${path.module}/erb_template.rb"]

    query = {
        erb_template = "${file("${path.module}/cloud-init.base.yaml.erb")}"

        domain = "${var.domain}"
        env = "${var.env}"
        role = "${var.role}"
    }
}

# These templates create cloud-init configuration that runs provision.sh with
# the specified arguments.
#
# The provision.sh script performs the major work of cloning the chef
# repositories and running chef-client over them.
#
# It also installs chef and all necessary bootstrapping dependencies as needed.
#
# We could really run the identity-devops and identity-devops-private chef
# provisioning in either order.
# - Benefit to running identity-devops first: we ensure that we have not
#   accidentally added any dependencies where identity-devops depends on
#   identity-devops-private.
# - Benefit to running identity-devops-private first: we immediately get unix
#   users created and set up, even when subsequent bootstrapping steps fail.
#
# Currently we run identity-devops-private first. Because the identity-devops
# cookbooks are so complicated and take so long to run, it's useful to have
# unix accounts set up early so we can SSH in to diagnose failures.
data "external" "cloud-init-provision-private-template" {
    program = ["ruby", "${path.module}/erb_template.rb"]

    query = {
        erb_template = "${file("${path.module}/cloud-init.provision.yaml.erb")}"

        # This will cause /run/<provision_phase_name> to be created if this
        # completes successfully.
        provision_phase_name = "private-provisioning"

        chef_download_sha256 = "${var.chef_download_sha256}"
        chef_download_url = "${var.chef_download_url}"

        git_clone_url = "${var.private_git_clone_url}"
        git_ref = "${var.private_git_ref}"
        s3_ssh_key_url = "${var.private_s3_ssh_key_url}"
    }
}

data "external" "cloud-init-provision-main-template" {
    program = ["ruby", "${path.module}/erb_template.rb"]

    query = {
        erb_template = "${file("${path.module}/cloud-init.provision.yaml.erb")}"

        # This will cause /run/<provision_phase_name> to be created if this
        # completes successfully.
        provision_phase_name = "main-provisioning"

        kitchen_subdir = "kitchen"
        berksfile_toplevel = "true"

        chef_download_sha256 = "${var.chef_download_sha256}"
        chef_download_url = "${var.chef_download_url}"

        git_clone_url = "${var.main_git_clone_url}"
        git_ref = "${var.main_git_ref}"
        s3_ssh_key_url = "${var.main_s3_ssh_key_url}"
    }
}

data "template_cloudinit_config" "bootstrap" {
    # may need to change these to true if we hit 16K in size
    gzip = false
    base64_encode = false

    part {
        filename = "set-hostname.yaml"
        content_type = "text/cloud-config"
        content = "${data.external.set-hostname-template.result.rendered}"
    }

    part {
        filename = "provision.sh"
        content_type = "text/x-shellscript"
        content = "${file("${path.module}/provision.sh")}"
    }

    part {
        filename = "base.yaml"
        content_type = "text/cloud-config"
        content = "${data.external.cloud-init-base-template.result.rendered}"
    }

    part {
        filename = "provision-private.yaml"
        content_type = "text/cloud-config"
        content = "${data.external.cloud-init-provision-private-template.result.rendered}"
    }

    part {
        filename = "provision-main.yaml"
        content_type = "text/cloud-config"
        content = "${data.external.cloud-init-provision-main-template.result.rendered}"
    }
}
