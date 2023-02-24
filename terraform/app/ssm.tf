# SSM Docs via module

locals {
  ssm_cmds = {
    "work-restart" = {
      command     = ["sudo systemctl restart idp-workers.target"]
      description = "Restart idp-worker service via systemctl"
      logging     = false
      use_root    = true
      parameters  = []
    }
    "passenger-restart" = {
      command = [
        "id-passenger-restart",
      ]
      description = "Restart passenger service via id-passenger-restart script"
      logging     = false
      use_root    = true
      parameters  = []
    }
    "scp-s3-cp" = {
      description = "Part of the scp-s3 devops script, runs an aws s3 cp command on the box"
      parameters = [
        {
          name        = "sourcefile"
          type        = "String"
          default     = "null"
          description = "source file to copy"
        },
        {
          name        = "destfile"
          type        = "String"
          default     = "null"
          description = "destination file to copy to"
        },
      ]
      logging  = false
      use_root = false
      command = [
        "aws s3 cp {{ sourcefile }} {{ destfile }}"
      ]
    }
  }
}

module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=8901b64186495c72fbca4c0929341f8663abad0a"
  #source = "../../../identity-terraform/ssm"

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
    },
    "rails-c" = {
      command     = "/usr/local/bin/id-rails-console"
      description = "Run id-rails-console"
      logging     = false
      use_root    = false
    }
    "rails-w" = {
      command     = "/usr/local/bin/id-rails-console --write"
      description = "Run id-rails-console with --write set"
      logging     = false
      use_root    = false
    }
    "uuid-lookup" = {
      command     = "/usr/local/bin/id-uuid-lookup"
      description = "Run users:lookup_by_email via id-uuid-lookup"
      logging     = true
      use_root    = false
    }
    "passenger-stat" = {
      command     = "sudo systemctl status passenger.service| grep Active"
      description = "Check status of passenger via systemctl, report Active line"
      logging     = true
      use_root    = false
    }
    "review-pass" = {
      command     = "/usr/local/bin/id-users-review-pass"
      description = "Run users:review:pass via id-users-review-pass"
      logging     = true
      use_root    = false
    }
    "review-reject" = {
      command     = "/usr/local/bin/id-users-review-reject"
      description = "Run users:review:reject via id-users-review-reject"
      logging     = true
      use_root    = false
    }
  }

  ssm_cmd_doc_map = (
    var.enable_loadtesting ? merge(local.locust_cmds, local.ssm_cmds) : local.ssm_cmds
  )
}

# Base role required for all instances
resource "aws_iam_role" "ssm-access" {
  name               = "${var.env_name}-ssm-access"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the ssm_access_role_policy
resource "aws_iam_role_policy" "ssm-access" {
  name   = "${var.env_name}-ssm-access"
  role   = aws_iam_role.ssm-access.id
  policy = module.ssm.ssm_access_role_policy
}

# IAM instance profile using the ssm-access role
resource "aws_iam_instance_profile" "ssm-access" {
  name = "${var.env_name}-ssm-access"
  role = aws_iam_role.ssm-access.name
}

###### uncomment when soc_destination_arn is valid ######
#module "log-ship-to-soc-ssm-logs" {
#source                              = "../modules/log_ship_to_soc"
#region                              = "us-west-2"
#cloudwatch_subscription_filter_name = "log-ship-to-soc"
#cloudwatch_log_group_name = {
#"${module.ssm.ssm_cw_logs}" = ""
#}
#env_name            = "${var.env_name}-ssm-logs"
#soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-ssm-lg"
#depends_on = [module.ssm.ssm_cw_logs]
#}
