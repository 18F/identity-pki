# SSM Docs via module
module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=88438f7586c277c0a85995e90efbbc9db563502d"
  #source = "../../../../identity-terraform/ssm"

  bucket_name_prefix = "login-gov"
  region             = var.region
  env_name           = var.env_name

  ssm_portforward_cmd_map = var.enable_portforwarding_ssm_commands ? {
    "redshift" = {
      description = "Document to start port forwarding session over Session Manager to private Redshift host"
      parameters = [
        {
          name        = "portNumber"
          type        = "String"
          default     = "5439"
          description = "(Optional) Port number of the server on the instance"
        },
        {
          name        = "localPortNumber"
          type        = "String"
          default     = "5439"
          description = "(Optional) Port number on local machine to forward traffic to. An open port is chosen at run-time if not provided"
        },
        {
          name        = "host"
          type        = "String"
          default     = split(":", aws_redshift_cluster.redshift.endpoint)[0]
          description = "(Optional) Hostname or IP address of the destination server"
        }
      ]
  } } : {}

  ssm_doc_map = {
    "default" = {
      command     = "/etc/update-motd.d/00-header ; cd ; /bin/bash"
      description = "Default shell to login as GSA_USERNAME"
      logging     = false
    },
    "sudo" = {
      command     = "sudo su -"
      description = "Login and change to root user"
      logging     = false
    },
    "rails-c" = {
      command     = "/usr/local/bin/id-rails-console"
      description = "Run id-rails-console"
      logging     = false
    },
    "rails-w" = {
      command     = "/usr/local/bin/id-rails-console --write"
      description = "Run id-rails-console with --write set"
      logging     = false
    },
    "tail-cw" = {
      command     = "sudo tail -f /var/log/cloud-init-output.log"
      description = "Tail the cloud-init-output logs"
      logging     = false
      use_root    = true
    },
  }
}
