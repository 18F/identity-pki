# The WAF acts as an ingress firewall for everything in our VPC.

resource "aws_wafregional_web_acl" "idp_web_acl" {
  count       = "${var.enable_waf ? 1 : 0}"
  # TODO: verify that we actually need the depends_on
  depends_on  = ["aws_alb.idp"]
  name        = "${var.env_name}-idp-web-acl"
  metric_name = "${var.env_name}IdPWebACL"

  default_action {
    type = "ALLOW"
  }

  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.waf_s3_stream.arn}"
  }

  rule {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = "${aws_wafregional_rule.idp_waf_rule1_passlist.id}"
    type     = "REGULAR"
  }
  rule {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = "${aws_wafregional_rule.idp_waf_rule2_blocklist.id}"
    type     = "REGULAR"
  }
  rule {
    action {
      type = "BLOCK"
    }

    priority = 3
    rule_id  = "${aws_wafregional_rule.idp_waf_rule3_bad_bots.id}"
    type     = "REGULAR"
  }
}

resource "aws_wafregional_web_acl_association" "idp_alb" {
  resource_arn = "${aws_alb.idp.arn}"
  web_acl_id   = "${aws_wafregional_web_acl.idp_web_acl.id}"
}

###############
# rules and ip sets
###############

# rule 1
# IP based passlist
resource "aws_wafregional_rule" "idp_waf_rule1_passlist" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule1"
  metric_name = "IdPWAFRule1"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule1_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule1_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "IdPWAFRule1IPSet"

  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.179/32"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.180/32"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.181/32"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.182/32"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.183/32"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "129.42.208.184/32"
  }
}

# rule 2
# IP based blocklist
resource "aws_wafregional_rule" "idp_waf_rule2_blocklist" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule2"
  metric_name = "IdPWAFRule2"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule2_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule2_ipset" {
  count       = "${var.enable_waf ? 1 : 0}"
  name = "IdPWAFRule2BlocklistIPSet"
}

# rule 3
# IP based bad bots blocklist
resource "aws_wafregional_rule" "idp_waf_rule3_bad_bots" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule3BadBots"
  metric_name = "IdPWAFRule3BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule3_ipset" {
  name = "IdPWAFRule3IPSet"
}

# rule 4
# IP Reputation List from https://www.spamhaus.org/
resource "aws_wafregional_rule" "idp_waf_rule4_" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule4_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "IdPWAFRule4IPSet"
}

# rule 5
# IP Reputation List from https://rules.emergingthreats.net/
# https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt
resource "aws_wafregional_rule" "idp_waf_rule5_" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule5_ipset" {
  count       = "${var.enable_waf ? 1 : 0}"
  name = "IdPWAFRule4IPSet"
}

# rule 6
# Tor exit points from https://check.torproject.org/exit-addresses
resource "aws_wafregional_rule" "idp_waf_rule6_" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule6_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "IdPWAFRule4IPSet"
}

# rule 7
# SQL Injection Conditions
resource "aws_wafregional_rule" "idp_waf_rule7_" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule7_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "IdPWAFRule4IPSet"
}

# rule 8
# XSS conditions
resource "aws_wafregional_rule" "idp_waf_rule8_" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule8_ipset" {
  count       = "${var.enable_waf ? 1 : 0}"
  name = "IdPWAFRule4IPSet"
}

###############
# logging
###############
resource "aws_kinesis_firehose_delivery_stream" "waf_s3_stream" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "aws-waf-logs-${var.env_name}-idp-waf-firehose-s3-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.waf_logbucket.arn}"
  }
}

resource "aws_s3_bucket" "waf_logbucket" {
  count  = "${var.enable_waf ? 1 : 0}"
  acl    = "private"
  # TODO use terraform locals to compute this once we upgrade to 0.10.*
  bucket = "${ "login-gov.waf-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}" }"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "logexpire"
    prefix  = ""
    enabled = true

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190 # 6 years
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}_firehose_waf_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "firehose_role_policy" {
    name = "${var.env_name}_firehose_waf_role_policy"
    role = "${aws_iam_role.firehose_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.waf_logbucket.arn}",
        "${aws_s3_bucket.waf_logbucket.arn}/*"
      ]
    }
  ]
}
EOF
}
