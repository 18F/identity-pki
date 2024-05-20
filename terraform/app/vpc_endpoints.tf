locals {
  aws_endpoints = {
    "dms"            = { vpc_cidr_egress = true },
    "kms"            = { vpc_cidr_egress = true },
    "logs"           = { vpc_cidr_egress = true },
    "monitoring"     = { vpc_cidr_egress = true },
    "ssm"            = { vpc_cidr_egress = true },
    "ssmmessages"    = { vpc_cidr_egress = true },
    "ec2"            = { vpc_cidr_egress = true },
    "ec2messages"    = { vpc_cidr_egress = true },
    "secretsmanager" = { vpc_cidr_egress = true },
    "sns"            = { vpc_cidr_egress = true },
    "lambda"         = { vpc_cidr_egress = false },
    "sqs"            = { vpc_cidr_egress = true },
    "sts"            = { vpc_cidr_egress = true },
    "events"         = { vpc_cidr_egress = true },
  }
}
