data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "env" {
  description = "Environment (prod/int/dev)"
}

variable "role" {
  description = "Host role (idp/jumphost/etc)"
}

variable "domain" {
  description = "Second level domain, e.g. login.gov"
}

variable "chef_download_url" {
  description = "URL to download chef debian package. If set to empty string, skip chef download."
  default     = ""
}

variable "chef_download_sha256" {
  description = "Expected SHA256 checksum of chef debian package"
  default     = ""
}

variable "private_s3_ssh_key_url" {
  description = "S3 URL to use to download SSH key used to clone the private_git_clone_url"
}

variable "private_git_clone_url" {
  description = "Git SSH URL used to clone identity-devops-private"
}

variable "private_git_ref" {
  description = "Git ref to check out after cloning private_git_clone_url"
  default     = "HEAD"
}

variable "private_lifecycle_hook_name" {
  description = "Name of the ASG lifecycle hook to notify upon private provision.sh completion"
  default     = "provision-private"
}

variable "main_s3_ssh_key_url" {
  description = "S3 URL to use to download SSH key used to clone the main_git_clone_url"
}

variable "main_git_clone_url" {
  description = "Git SSH URL used to clone identity-devops"
}

variable "main_git_ref_map" {
  description = "Mapping from role to the git ref to check out after cloning main_git_clone_url"
  type        = map(string)
  default     = {}
}

variable "main_git_ref_default" {
  description = "Default git ref to check out after cloning main_git_clone_url if no value set for role in main_git_ref_map"
  default     = "HEAD"
}

variable "proxy_server" {
  description = "URL to outbound proxy server"
}

variable "proxy_port" {
  description = "Port for outbound proxy server"
}

variable "no_proxy_hosts" {
  description = "Comma delimited list of hostnames, ip's and domains that should not use outbound proxy"
}

variable "proxy_enabled_roles" {
  description = "Mapping from role names to integer {0,1} for whether the outbound proxy server is enabled during bootstrapping."
  type        = map(number)
}

variable "main_lifecycle_hook_name" {
  description = "Name of the ASG lifecycle hook to notify upon main provision.sh completion"
  default     = "provision-main"
}

variable "override_asg_name" {
  description = "Auto scaling group name. If not set, defaults to $env-$role"
  default     = ""
}

variable "sns_topic_arn" {
  description = "ARN to send alerts alerts to, ultimately triggering Slack or other message"
  default     = ""
}

locals {
  asg_name = var.override_asg_name != "" ? var.override_asg_name : "${var.env}-${var.role}"
}

locals {
  main_git_ref = lookup(var.main_git_ref_map, var.role, var.main_git_ref_default)

  # set proxy locals to "" unless there is a 1 for our role (or default unknown) in proxy_enabled_roles
  proxy_server = lookup(
    var.proxy_enabled_roles,
    var.role,
    var.proxy_enabled_roles["unknown"],
  ) == 1 ? "${var.proxy_server}\\n" : ""
  proxy_port = lookup(
    var.proxy_enabled_roles,
    var.role,
    var.proxy_enabled_roles["unknown"],
  ) == 1 ? "${var.proxy_port}\\n" : ""
  no_proxy_hosts = lookup(
    var.proxy_enabled_roles,
    var.role,
    var.proxy_enabled_roles["unknown"],
  ) == 1 ? "${var.no_proxy_hosts}\\n" : ""
  proxy_url = lookup(
    var.proxy_enabled_roles,
    var.role,
    var.proxy_enabled_roles["unknown"],
  ) == 1 ? "http://${var.proxy_server}:${var.proxy_port}\\n" : ""

  apt_proxy_data = <<EOF
 - path: /etc/apt/apt.conf.d/proxy.conf
   content: |
     Acquire::http::Proxy "http://${var.proxy_server}:${var.proxy_port}";
     Acquire::https::Proxy "http://${var.proxy_server}:${var.proxy_port}";
EOF
  apt_proxy_stanza = lookup(
    var.proxy_enabled_roles,
    var.role,
    var.proxy_enabled_roles["unknown"],
  ) == 1 ? local.apt_proxy_data : ""
}

output "main_git_ref" {
  value = local.main_git_ref
}

output "private_git_ref" {
  value = var.private_git_ref
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
  value = data.template_cloudinit_config.bootstrap.rendered
}

data "template_file" "set-hostname-template" {
  template = file("${path.module}/cloud-init.hostname.yaml.tpl")
  vars = {
    hostname_prefix = var.role
    domain          = "${var.env}.${var.domain}"
  }
}

data "template_file" "cloud-init-base-template" {
  template = file("${path.module}/cloud-init.base.yaml.tpl")
  vars = {
    apt_proxy_stanza = local.apt_proxy_stanza
    domain           = var.domain
    env              = var.env
    no_proxy_hosts   = local.no_proxy_hosts
    proxy_port       = local.proxy_port
    proxy_server     = local.proxy_server
    proxy_url        = local.proxy_url
    region           = data.aws_region.current.name
    role             = var.role
    sns_topic_arn    = var.sns_topic_arn
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
data "template_file" "cloud-init-provision-private-template" {
  template = file("${path.module}/cloud-init.provision.yaml.tpl")
  vars = {
    # This will cause /run/<provision_phase_name> to be created if this
    # completes successfully.
    provision_phase_name = "private-provisioning"
    kitchen_subdir       = ""
    berksfile_toplevel   = ""
    chef_download_sha256 = var.chef_download_sha256
    chef_download_url    = var.chef_download_url
    git_clone_url        = var.private_git_clone_url
    git_ref              = var.private_git_ref
    s3_ssh_key_url       = var.private_s3_ssh_key_url
    asg_name             = local.asg_name
    lifecycle_hook_name  = var.private_lifecycle_hook_name
    run_remove_advantage = "echo not removing advantage client yet"
    run_aide             = "echo not running aideinit"

  }
}

data "template_file" "cloud-init-provision-main-template" {
  template = file("${path.module}/cloud-init.provision.yaml.tpl")
  vars = {
    # This will cause /run/<provision_phase_name> to be created if this
    # completes successfully.
    provision_phase_name = "main-provisioning"
    kitchen_subdir       = "--kitchen-subdir kitchen"
    berksfile_toplevel   = "--berksfile-toplevel"
    chef_download_sha256 = var.chef_download_sha256
    chef_download_url    = var.chef_download_url
    git_clone_url        = var.main_git_clone_url
    git_ref              = local.main_git_ref
    s3_ssh_key_url       = var.main_s3_ssh_key_url
    asg_name             = local.asg_name
    lifecycle_hook_name  = var.main_lifecycle_hook_name
    run_remove_advantage = "apt remove -y ubuntu-advantage-pro ubuntu-advantage-tools"
    run_aide             = "aideinit --force --yes && touch /var/tmp/ran-aideinit"
  }
}

data "template_cloudinit_config" "bootstrap" {
  # may need to change these to true if we hit 16K in size
  gzip          = true
  base64_encode = true

  part {
    filename     = "set-hostname.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.set-hostname-template.rendered
  }

  part {
    filename     = "provision.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/provision.sh")
  }

  part {
    filename     = "base.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-init-base-template.rendered
  }

  part {
    filename     = "provision-private.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-init-provision-private-template.rendered
  }

  part {
    filename     = "provision-main.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-init-provision-main-template.rendered
  }
}
