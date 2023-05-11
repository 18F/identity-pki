# SSM Docs via module

locals {
  ssm_cmds = {
    "work-restart" = {
      command     = ["sudo systemctl restart idp-workers.target"]
      description = "Restart idp-worker service via systemctl"
      logging     = false
      parameters  = []
    }
    "passenger-restart" = {
      command = [
        "id-passenger-restart",
      ]
      description = "Restart passenger service via id-passenger-restart script"
      logging     = false
      parameters  = []
    }
    "data-pull" = {
      description = "Calls the data-pull script in the IDP repo"
      parameters = [
        {
          name        = "subcommand"
          type        = "String"
          default     = "null"
          description = "data-pull subcommand and its arguments, MUST BE SHELLESCAPED"
        },
        {
          name        = "reason"
          type        = "String"
          default     = "null"
          description = "reason for the pull, MUST BE SHELLESCAPED"
        },
        {
          name        = "investigator"
          type        = "String"
          default     = "null"
          description = "name of investigator, MUST BE SHELLESCAPED"
        },
        {
          name        = "awsusername"
          type        = "String"
          default     = "null"
          description = "AWS username of script runner, MUST BE SHELLESCAPED"
        }
      ]
      logging = false
      command = [
        "audit_message_path=$(mktemp)",
        "command_output_path=$(mktemp)",
        # The {{ parameters }} here rely on control characters being shellescaped by the calling script!
        # The * and ` are for markdown formatting of the audit message that we post to Slack
        "echo \\*AWS_USER@Box\\*: \\`{{ awsusername }}\\` @ \\`$(hostname)\\` >> $audit_message_path",
        "echo \\*Investigator\\*: {{ investigator }} >> $audit_message_path",
        "echo \\*Reason\\*: {{ reason }} >> $audit_message_path",
        "cd /srv/idp/current; ./bin/data-pull {{ subcommand }} 2>> $audit_message_path > $command_output_path",
        "cat $audit_message_path | notify-slack --username data-pull --text - --icon terminal --channel \"$(cat /etc/login.gov/keys/slackchannel)\" --webhook \"$(cat /etc/login.gov/keys/slackwebhook)\" --raise 1>&2 || exit 1",
        "cat $command_output_path",
      ]
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
      logging = false
      command = [
        "aws s3 cp {{ sourcefile }} {{ destfile }}"
      ]
    }
  }
}

module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=16554935ff6fe92b77a29a3bcd4b04072d65e264"
  #source = "../../../identity-terraform/ssm"

  bucket_name_prefix = "login-gov"
  region             = var.region
  env_name           = var.env_name

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
    }
    "rails-w" = {
      command     = "/usr/local/bin/id-rails-console --write"
      description = "Run id-rails-console with --write set"
      logging     = false
    }
    "uuid-lookup" = {
      command     = "/usr/local/bin/id-uuid-lookup"
      description = "Run users:lookup_by_email via id-uuid-lookup"
      logging     = true
    }
    "passenger-stat" = {
      command     = "sudo systemctl status passenger.service| grep Active"
      description = "Check status of passenger via systemctl, report Active line"
      logging     = true
    }
    "review-pass" = {
      command     = "/usr/local/bin/id-users-review-pass"
      description = "Run users:review:pass via id-users-review-pass"
      logging     = true
    }
    "review-reject" = {
      command     = "/usr/local/bin/id-users-review-reject"
      description = "Run users:review:reject via id-users-review-reject"
      logging     = true
    }
  }

  ssm_cmd_doc_map = (
    var.enable_loadtesting ? merge(local.locust_cmds, local.ssm_cmds) : local.ssm_cmds
  )

  ssm_interactive_cmd_map = {
    "tail-cw" = {
      description = "Tail the cloud-init-output logs"
      parameters = [
        {
          name        = "logpath"
          type        = "String"
          default     = "/var/log/cloud-init-output.log"
          description = "log file to tail/read"
          pattern     = "^[a-zA-Z0-9-_/]+(.log)$"
        }
      ]
      command = ["tail -f {{ logpath }}"]
    }
  }
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
