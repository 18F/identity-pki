resource "aws_ecr_pull_through_cache_rule" "public_aws" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_pull_through_cache_rule" "public_kubernetes" {
  ecr_repository_prefix = "kubernetes"
  upstream_registry_url = "registry.k8s.io"
}

resource "aws_ecr_pull_through_cache_rule" "public_quay" {
  ecr_repository_prefix = "quay"
  upstream_registry_url = "quay.io"
}

resource "aws_ecr_pull_through_cache_rule" "public_docker_hub" {
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = module.dockerhub_credentials.secret_id
}

resource "aws_ecr_pull_through_cache_rule" "public_github" {
  ecr_repository_prefix = "github"
  upstream_registry_url = "ghcr.io"
  credential_arn        = module.github_credentials.secret_id
}

resource "aws_ecr_registry_scanning_configuration" "main" {
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = var.scan_on_push_filter
      filter_type = "WILDCARD"
    }
  }

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = var.continuous_scan_filter
      filter_type = "WILDCARD"
    }
  }
}

module "dockerhub_credentials" {
  source = "../../modules/secrets_manager_secret"

  secret_name = "ecr-pullthroughcache/dockerhub"
  secret_string = jsonencode(
    {
      username    = "CHANGEME"
      accessToken = "CHANGEME"
    }
  )
}

module "github_credentials" {
  source = "../../modules/secrets_manager_secret"

  secret_name = "ecr-pullthroughcache/github"
  secret_string = jsonencode(
    {
      username    = "CHANGEME"
      accessToken = "CHANGEME"
    }
  )
}
