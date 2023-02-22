locals {
  asg_name     = var.override_asg_name != "" ? var.override_asg_name : "${var.env}-${var.role}"
  provision_sh = file("${path.module}/provision.sh")

  base_yaml = templatefile("${path.module}/cloud-init.base.yaml.tpl",
    {
      apt_proxy_stanza            = local.apt_proxy_stanza,
      asg_name                    = local.asg_name,
      chef_download_sha256        = var.chef_download_sha256,
      chef_download_url           = var.chef_download_url,
      domain                      = var.domain,
      env                         = var.env,
      hostname_prefix             = var.role,
      main_git_clone_url          = var.main_git_clone_url,
      main_lifecycle_hook_name    = var.main_lifecycle_hook_name,
      main_git_ref                = local.main_git_ref,
      main_s3_ssh_key_url         = var.main_s3_ssh_key_url,
      no_proxy_hosts              = local.no_proxy_hosts,
      private_git_clone_url       = var.private_git_clone_url,
      private_lifecycle_hook_name = var.private_lifecycle_hook_name,
      private_git_ref             = var.private_git_ref,
      private_s3_ssh_key_url      = var.private_s3_ssh_key_url,
      proxy_port                  = local.proxy_port,
      proxy_server                = local.proxy_server,
      proxy_url                   = local.proxy_url,
      region                      = data.aws_region.current.name,
      role                        = var.role,
      sns_topic_arn               = var.sns_topic_arn
    }
  )

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

# Ideally this module would have contained the aws_launch_configuration since
# it looks pretty much the same across auto scaling groups.
# But this was not possible due to a terraform bug:
# https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See ./vestigial.tf.txt for config that may be useful to implement this if the
# terraform bug is ever fixed.

# The output of this module is a rendered cloud-init user data script,
# appropriate for including in an aws_launch_configuration resource.

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

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "cloudinit_config" "bootstrap" {
  # may need to change these to true if we hit 16K in size
  gzip          = true
  base64_encode = true

  part {
    filename     = "provision.sh"
    content_type = "text/x-shellscript"
    content      = local.provision_sh
  }

  part {
    filename     = "base.yaml"
    content_type = "text/cloud-config"
    content      = local.base_yaml
  }
}

resource "aws_s3_object" "provision_sh" {
  bucket       = var.s3_secrets_bucket_name
  key          = "${var.env}/user-data/${var.role}/provision.sh"
  content      = local.provision_sh
  content_type = "text/plain"
}

resource "aws_s3_object" "base_yaml" {
  bucket       = var.s3_secrets_bucket_name
  key          = "${var.env}/user-data/${var.role}/base.yaml"
  content      = local.base_yaml
  content_type = "text/plain"
}