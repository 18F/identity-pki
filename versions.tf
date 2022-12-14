# If you are updating plugins in here, be sure to transfer the old versions
# over to the versions.tf.old file, so that it won't break people who are
# running auto-tf on branches that don't have your latest/greatest stuff.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.40.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.3"
    }
    github = {
      source  = "integrations/github"
      version = "5.9.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.7.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = "1.3.5"
}

provider "aws" {
  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }
  region            = var.region
  use_fips_endpoint = true
  endpoints {
    appautoscaling   = "https://application-autoscaling.${var.region}.amazonaws.com"
    autoscaling      = "https://autoscaling.${var.region}.amazonaws.com"
    autoscalingplans = "https://autoscaling-plans.${var.region}.amazonaws.com"
    cloudfront       = "https://cloudfront-fips.amazonaws.com"
    route53resolver  = "https://route53resolver.${var.region}.amazonaws.com"
    s3               = "https://s3.${var.region}.amazonaws.com"
  }
}

provider "aws" {
  alias             = "dr"
  region            = var.dr_region
  use_fips_endpoint = true
  endpoints {
    appautoscaling   = "https://application-autoscaling.${var.region}.amazonaws.com"
    autoscaling      = "https://autoscaling.${var.region}.amazonaws.com"
    autoscalingplans = "https://autoscaling-plans.${var.region}.amazonaws.com"
    cloudfront       = "https://cloudfront-fips.amazonaws.com"
    route53resolver  = "https://route53resolver.${var.region}.amazonaws.com"
    s3               = "https://s3.amazonaws.com"
  }
}

provider "aws" {
  alias             = "use1"
  region            = "us-east-1"
  use_fips_endpoint = true
  endpoints {
    appautoscaling   = "https://application-autoscaling.${var.region}.amazonaws.com"
    autoscaling      = "https://autoscaling.${var.region}.amazonaws.com"
    autoscalingplans = "https://autoscaling-plans.${var.region}.amazonaws.com"
    cloudfront       = "https://cloudfront-fips.amazonaws.com"
    route53resolver  = "https://route53resolver.${var.region}.amazonaws.com"
    s3               = "https://s3.amazonaws.com"
  }
}

provider "aws" {
  alias             = "usw2"
  region            = var.region
  use_fips_endpoint = true
  endpoints {
    appautoscaling   = "https://application-autoscaling.${var.region}.amazonaws.com"
    autoscaling      = "https://autoscaling.${var.region}.amazonaws.com"
    autoscalingplans = "https://autoscaling-plans.${var.region}.amazonaws.com"
    cloudfront       = "https://cloudfront-fips.amazonaws.com"
    route53resolver  = "https://route53resolver.${var.region}.amazonaws.com"
    s3               = "https://s3.${var.region}.amazonaws.com"
  }
}
