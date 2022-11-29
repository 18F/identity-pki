# SSM Docs via module
module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  # source = "../../../../identity-terraform/ssm"

  bucket_name_prefix = "login-gov"
  region             = var.region
  env_name           = var.env_name

  ssm_doc_map = {
    "default" = {
      command     = "/etc/update-motd.d/00-header ; cd ; /bin/bash"
      description = "Default shell to login as GSA_USERNAME"
      logging     = false
      use_root    = false
    },
    "sudo" = {
      command     = "sudo su -"
      description = "Login and change to root user"
      logging     = false
      use_root    = false
    },
    "tail-cw" = {
      command     = "sudo tail -f /var/log/cloud-init-output.log"
      description = "Tail the cloud-init-output logs"
      logging     = false
      use_root    = true
    }
  }
}