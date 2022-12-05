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
  region = var.region
  endpoints {
        acm            = "https://acm-fips.${var.region}.amazonaws.com"
        apigateway     = "https://apigateway-fips.${var.region}.amazonaws.com"
        athena         = "https://athena-fips.${var.region}.amazonaws.com"
        cloudformation = "https://cloudformation-fips.${var.region}.amazonaws.com"
        cloudtrail     = "https://cloudtrail-fips.${var.region}.amazonaws.com"
        codebuild      = "https://codebuild-fips.${var.region}.amazonaws.com"
        codecommit     = "https://codecommit-fips.${var.region}.amazonaws.com"
        codepipeline   = "https://codepipeline-fips.${var.region}.amazonaws.com"
        configservice  = "https://config-fips.${var.region}.amazonaws.com"
        detective      = "https://api.detective-fips.${var.region}.amazonaws.com"
        devopsguru     = "https://devops-guru-fips.${var.region}.amazonaws.com"
        dms            = "https://dms-fips.${var.region}.amazonaws.com"
        dynamodb       = "https://dynamodb-fips.${var.region}.amazonaws.com"
        ec2            = "https://ec2-fips.${var.region}.amazonaws.com"
        ecr            = "https://ecr-fips.${var.region}.amazonaws.com"
        elasticache    = "https://elasticache-fips.${var.region}.amazonaws.com"
        elb            = "https://elasticloadbalancing-fips.${var.region}.amazonaws.com"
        eks            = "https://fips.eks.${var.region}.amazonaws.com"
        firehose       = "https://firehose-fips.${var.region}.amazonaws.com"
        glue           = "https://glue-fips.${var.region}.amazonaws.com"
        guardduty      = "https://guardduty-fips.${var.region}.amazonaws.com"
        inspector      = "https://inspector-fips.${var.region}.amazonaws.com"
        kinesis        = "https://kinesis-fips.${var.region}.amazonaws.com"
        kms            = "https://kms-fips.${var.region}.amazonaws.com"
        lambda         = "https://lambda-fips.${var.region}.amazonaws.com"
        macie          = "https://macie-fips.${var.region}.amazonaws.com"
        macie2         = "https://macie2-fips.${var.region}.amazonaws.com"
        opensearch     = "https://es-fips.${var.region}.amazonaws.com"
        pinpoint       = "https://pinpoint-fips.${var.region}.amazonaws.com"
        quicksight     = "https://fips-${var.region}.quicksight.aws.amazon.com"
        redshift       = "https://redshift-fips.${var.region}.amazonaws.com"
        rds            = "https://rds-fips.${var.region}.amazonaws.com"
        route53        = "https://route53-fips.amazonaws.com"
        secretsmanager = "https://secretsmanager-fips.${var.region}.amazonaws.com"
        servicecatalog = "https://servicecatalog-fips.${var.region}.amazonaws.com"
        ses            = "https://email-fips.${var.region}.amazonaws.com"
        shield         = "https://shield-fips.${var.region}.amazonaws.com"
        sns            = "https://sns-fips.${var.region}.amazonaws.com"
        sqs            = "https://sqs-fips.${var.region}.amazonaws.com"
        ssm            = "https://ssm-fips.${var.region}.amazonaws.com"
        sts            = "https://sts-fips.${var.region}.amazonaws.com"
        waf            = "https://waf-fips.amazonaws.com"
        wafregional    = "https://waf-regional-fips.${var.region}.amazonaws.com"
        wafv2          = "https://wafv2-fips.${var.region}.amazonaws.com"
        xray           = "https://xray-fips.${var.region}.amazonaws.com"
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "usw2"
  region = var.region
}
