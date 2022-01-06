provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling
  profile             = "login-tooling"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

locals {
  repos = {
    alpha = {
      name                    = "alpha/base"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    alpine = {
      name                    = "alpine/git"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    fluent-bit = {
      name                    = "amazon/aws-for-fluent-bit"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    gitaly = {
      name                    = "gitlab-org/build/cng/gitaly"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    gitlabdemo = {
      name                    = "gitlabdemo"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    golang = {
      name                    = "library/golang"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
    tspencertest = {
      name                    = "tspencertest"
      ecr_repo_tag_mutability = "MUTABLE"
      tags = {
        gitlab_alpha_build    = "write"
        gitlab_bravo_build    = "write"
        gitlab_charlie_build  = "write"
        gitlab_delta_build    = "write"
        gitlab_echo_build     = "write"
      }
    }
  }
}

module "settings" {
  source = "../module-ecr-global-settings"

  continuous_scan_filter = "*"
  env                    = "tooling"
  region                 = "us-west-2"
  scan_on_push_filter    = "*"
}

module "repos" {
  for_each = local.repos
  source   = "../module-ecr-repo"

  ecr_repo_name             = each.value.name
  encryption_type           = "AES256"
  env                       = "tooling"
  kms_key                   = null
  region                    = "us-west-2"
  tags                      = each.value.tags
}
