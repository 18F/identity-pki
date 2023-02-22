output "main_git_ref" {
  value = local.main_git_ref
}

output "private_git_ref" {
  value = var.private_git_ref
}

output "rendered_cloudinit_config" {
  value     = data.cloudinit_config.bootstrap.rendered
  sensitive = true
}