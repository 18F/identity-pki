# SSM command docs for locust; defined as local.locust_cmds
# so that it can be merged with var.ssm_cmd_doc_map in the ssm module

locals {
  locust_cmds = {
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
          default     = "pt"
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
}
