# SSM Docs via module

locals {
  locust_cmds_instructions = {
    "locust-leader" = {
      command = [
        "rm -rf /tmp/pocust",
        "mkdir /tmp/pocust",
        "ulimit -n 10240",
        "for i in `seq 1 $(($(nproc)-2))`; do NUM_USERS={{NUMUSERS}} /usr/local/bin/id-locust {{TEST}} {{ENV}} -w 127.0.0.1 & done",
        "TMOUT=900000 NUM_USERS={{NUMUSERS}} /usr/local/bin/id-locust {{TEST}} {{ENV}} -u {{USERS}} -r {{SPAWNRATE}} -n {{NUMUSERS}} -t {{RUNTIME}} -m -p",
        "cp /var/log/loadtest/* /tmp/pocust/",
        "aws s3 cp /tmp/pocust/ s3://login-gov.transfer-utility.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/out/pocust/ --recursive",
      ]
      description = "Initiates the locust master service and local workers with remaining cores"
      logging     = false
      use_root    = true
      parameters = [
        {
          name        = "TEST"
          type        = "String"
          default     = "sign_in"
          description = "Selected Locust Test"
        },
        {
          name        = "ENV"
          type        = "String"
          default     = "pt"
          description = "Target Environment to Run Against"
        },
        {
          name        = "USERS"
          type        = "String"
          default     = "\"10\""
          description = "Peak number of concurrent Locust Users"
        },
        {
          name        = "NUMUSERS"
          type        = "String"
          default     = "\"100\""
          description = "Total available Locust Users"
        },
        {
          name        = "RUNTIME"
          type        = "String"
          default     = "60s"
          description = "Total runtime of test"
        },
        {
          name        = "SPAWNRATE"
          type        = "String"
          default     = "\"10\""
          description = "Hatch rate of users. (Users per second.)"
        },

      ]

    },
    "locust-worker" = {
      command = [
        "ulimit -n 10240",
        "for i in `seq 1 $(($(nproc)-1))`; do NUM_USERS={{NUMUSERS}} /usr/local/bin/id-locust {{TEST}} {{ENV}} -w {{MASTERIP}} & done",
      ]
      description = "Initiates workers that connect to the locust-leader"
      logging     = false
      use_root    = false
      parameters = [
        {
          name        = "TEST"
          type        = "String"
          default     = "sign_in"
          description = "Selected Locust Test Type"
        },
        {
          name        = "ENV"
          type        = "String"
          default     = "henrydrich"
          description = "Target Environment to Run Against"
        },
        {
          name        = "NUMUSERS"
          type        = "String"
          default     = "\"100\""
          description = "Total available Locust Users"
        },
        {
          name        = "MASTERIP"
          type        = "String"
          default     = "127.0.0.1"
          description = "Ip address of locust-leader"
        }
      ]
    }
    "locust-leader-footprint" = {
      command = [
        "rm -rf /tmp/pocust",
        "mkdir -p /tmp/pocust",
        "echo '# Repositories' > /tmp/pocust/$(hostname)-pocust.txt",
        "echo -n '/etc/login.gov/repos/identity-loadtest:' >> /tmp/pocust/$(hostname)-pocust.txt",
        "cd /etc/login.gov/repos/identity-loadtest/",
        "git describe --always --tags >> /tmp/pocust/$(hostname)-pocust.txt",
        "echo '#Uploading locust output files'",
        "aws s3 cp /tmp/pocust/* s3://login-gov.transfer-utility.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/out/pocust/",
        "echo '#Cleaning up locust output files'",
        "rm -rf /tmp/pocust",
        "rm -f /var/log/load_test/*'"
      ]
      description = "Footprints locust-leader and uploads results to transfer-utility"
      logging     = false
      use_root    = true
      parameters  = []
    }
    "idp-footprint" = {
      command = [
        "rm -rf /tmp/pocust",
        "mkdir /tmp/pocust",
        "echo '# Repositories' > /tmp/pocust/$(hostname)-pocust.txt",
        "sudo bash -c 'for r in {{IDPREPOS}}; do cd $r ; echo -n $r >> /tmp/pocust/$(hostname)-pocust.txt; echo -n ':'  >> /tmp/pocust/$(hostname)-pocust.txt ; git describe --always --tags >> /tmp/pocust/$(hostname)-pocust.txt ; done'",
        "echo '# IdP deploy.json' >> /tmp/pocust/$(hostname)-pocust.txt",
        "cat /srv/idp/current/public/api/deploy.json >> /tmp/pocust/$(hostname)-pocust.txt",
        "echo '# Configuration' >> /tmp/pocust/$(hostname)-pocust.txt",
        "for f in {{IDPFILES}}; do sudo sha256sum --tag $f >> /tmp/pocust/$(hostname)-pocust.txt ; done",
        "echo '#Uploading output files'",
        "aws s3 cp /tmp/pocust/* s3://login-gov.transfer-utility.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/out/pocust/",
        "rm -rf /tmp/pocust"
      ]
      description = "Footprints idp host and uploads results to transfer-utility"
      logging     = false
      use_root    = true
      parameters = [
        {
          name        = "IDPREPOS"
          type        = "String"
          default     = "/etc/login.gov/repos/identity-devops /etc/login.gov/repos/identity-devops-private /srv/idp/current"
          description = "List of Repos to fingerprint"
        },
        {
          name        = "IDPFILES"
          type        = "String"
          default     = "/srv/idp/current/config/application_s3_env.yml /srv/idp/current/config/application.yml"
          description = "List of Configuration Files to fingerprint"
        },

      ]
    }
  }
  ssm_cmd_map = var.enable_loadtesting ? merge(local.locust_cmds_instructions) : merge({})
}

module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=daa7895211703a960cc9a53a05ce16db5d529cf0"
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
    "work-restart" = {
      command     = "sudo systemctl restart idp-workers.target"
      description = "Restart idp-worker service via systemctl"
      logging     = true
      use_root    = false
    }
    "passenger-stat" = {
      command     = "sudo systemctl status passenger.service| grep Active"
      description = "Check status of passenger service via systemctl, report Active line"
      logging     = true
      use_root    = false
    }
    "passenger-restart" = {
      command     = "sudo systemctl restart passenger; if [ $? -eq 0 ]; then echo SUCCESS; else echo FAIL && exit ; fi"
      description = "Restart passenger service via systemctl"
      logging     = true
      use_root    = false
    }
  }

  ssm_cmd_doc_map = local.ssm_cmd_map
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
