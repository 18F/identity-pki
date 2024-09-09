# SSM Docs via module

locals {
  ssm_cmds = {
    "action-account" = {
      description = "Calls the action-account script in the IDP repo"
      parameters = [
        {
          name        = "subcommand"
          type        = "String"
          default     = "null"
          description = "action-account subcommand and its arguments, MUST BE SHELLESCAPED"
        },
        {
          name        = "reason"
          type        = "String"
          default     = "null"
          description = "reason for the action, MUST BE SHELLESCAPED"
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
        "cd /srv/idp/current; bundle exec ./bin/action-account {{ subcommand }} 2>> $audit_message_path > $command_output_path",
        "cat $audit_message_path | notify-slack --username action-account --text - --icon terminal --channel \"$(cat /etc/login.gov/keys/slackchannel)\" --webhook \"$(cat /etc/login.gov/keys/slackwebhook)\" --raise 1>&2 || exit 1",
        "cat $command_output_path",
      ]
    }
    "work-restart" = {
      command     = ["sudo systemctl restart idp-workers.target"]
      description = "Restart idp-worker service via systemctl"
      logging     = false
      parameters  = []
    }
    "puma-restart" = {
      command = [
        "id-puma-restart",
      ]
      description = "Restart puma service via id-puma-restart script"
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
        "cd /srv/idp/current; bundle exec ./bin/data-pull {{ subcommand }} 2>> $audit_message_path > $command_output_path",
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

  ssm_docs = {
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
  }

  ssm_interactive_cmds = {
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

module "ssm_uw2" {
  source = "github.com/18F/identity-terraform//ssm?ref=8f71136f23cb01cc09d86d68f7403d1fe8498ea4"
  #source = "../../../identity-terraform/ssm"

  bucket_name_prefix = "login-gov"
  region             = var.region
  env_name           = var.env_name

  ssm_doc_map             = local.ssm_docs
  ssm_interactive_cmd_map = local.ssm_interactive_cmds
  ssm_cmd_doc_map = (
    var.enable_loadtesting ? merge(local.locust_cmds, local.ssm_cmds) : local.ssm_cmds
  )
}

module "ssm_ue1" {
  count  = var.enable_us_east_1_infra ? 1 : 0
  source = "github.com/18F/identity-terraform//ssm?ref=8f71136f23cb01cc09d86d68f7403d1fe8498ea4"
  #source = "../../../identity-terraform/ssm"
  providers = {
    aws = aws.use1
  }

  bucket_name_prefix = "login-gov"
  region             = "us-east-1"
  env_name           = var.env_name

  ssm_doc_map             = local.ssm_docs
  ssm_interactive_cmd_map = local.ssm_interactive_cmds
  ssm_cmd_doc_map = (
    var.enable_loadtesting ? merge(local.locust_cmds, local.ssm_cmds) : local.ssm_cmds
  )
}

# Base role required for all instances
resource "aws_iam_role" "ssm-access" {
  name               = "${var.env_name}-ssm-access"
  assume_role_policy = module.application_iam_roles.assume_role_from_vpc_json
}

# Role policy that associates it with the ssm_access_role_policy
resource "aws_iam_role_policy" "ssm_access_uw2" {
  name   = "${var.env_name}-ssm-access-uw2"
  role   = aws_iam_role.ssm-access.id
  policy = module.ssm_uw2.ssm_access_role_policy
  lifecycle { create_before_destroy = true }
}

# for us-east-1 as well
resource "aws_iam_role_policy" "ssm_access_ue1" {
  count = var.enable_us_east_1_infra ? 1 : 0

  name   = "${var.env_name}-ssm-access-ue1"
  role   = aws_iam_role.ssm-access.id
  policy = module.ssm_ue1[count.index].ssm_access_role_policy
  lifecycle { create_before_destroy = true }
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
#"${module.ssm_uw2.ssm_cw_logs}" = ""
#}
#env_name            = "${var.env_name}-ssm-logs"
#soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-ssm-lg"
#depends_on = [module.ssm_uw2.ssm_cw_logs]
#}
