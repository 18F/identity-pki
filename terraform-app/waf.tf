# The WAF acts as an ingress firewall for the IdP ALB.
resource "aws_wafregional_web_acl" "idp_web_acl" {
  count       = "${var.enable_waf ? 1 : 0}"
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
    rule_id  = "${aws_wafregional_rule.idp_waf_rule1_pass_list.id}"
    type     = "REGULAR"
  }
  rule {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = "${aws_wafregional_rule.idp_waf_rule2_block_list.id}"
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
  rule {
    action {
      type = "BLOCK"
    }

    priority = 4
    rule_id  = "${aws_wafregional_rule.idp_waf_rule4_reputation_lists.id}"
    type     = "REGULAR"
  }
  rule {
    action {
      type = "BLOCK"
    }

    priority = 5
    rule_id  = "${aws_wafregional_rule.idp_waf_rule5_sqli.id}"
    type     = "REGULAR"
  }
  rule {
    action {
      type = "BLOCK"
   }

  priority = 6
  rule_id  = "${aws_wafregional_rule.idp_waf_rule6_xss.id}"
  type     = "REGULAR"
  }
}

resource "aws_wafregional_web_acl_association" "idp_alb" {
  count        = "${var.enable_waf ? 1 : 0}"
  resource_arn = "${aws_alb.idp.arn}"
  web_acl_id   = "${aws_wafregional_web_acl.idp_web_acl.id}"
}

###############
# rules and ip sets
# Aside from the SQLi and XSS rules, the IP Set values are maintained 
# by lambda functions found in the dentity-lambda-functions-repo: 
# https://github.com/18F/identity-lambda-functions
#
# The SQLi and XSS rules update the IP Sets based on the configured
# SQLi and XSS matchsets, ex:
# https://www.terraform.io/docs/providers/aws/r/waf_sql_injection_match_set.html
###############

# rule 1
# IP based passlist
resource "aws_wafregional_rule" "idp_waf_rule1_pass_list" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule1PassList"
  metric_name = "${var.env_name}IdPWAFRule1PassList"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule1_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule1_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule1PassListIPSet"

  ip_set_descriptor {
    type  = "IPV4"
    value = "${element(var.waf_whitelisted_ips, 0)}"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "${element(var.waf_whitelisted_ips, 1)}"
  }
  ip_set_descriptor {
    type  = "IPV4"
    value = "${element(var.waf_whitelisted_ips, 2)}"
  }
}

# rule 2
# IP based blocklist
resource "aws_wafregional_rule" "idp_waf_rule2_block_list" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule2BlockList"
  metric_name = "${var.env_name}IdPWAFRule2BlockList"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule2_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule2_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule2BlocklistIPSet"
}

# rule 3
# IP based bad bots list
resource "aws_wafregional_rule" "idp_waf_rule3_bad_bots" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule3BadBots"
  metric_name = "${var.env_name}IdPWAFRule3BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule3_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule3BadBotsIPSet"
}

# rule 4
# Aggregate IP Reputation List from:
# https://www.spamhaus.org/drop/drop.txt,
# https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt,
# and, https://check.torproject.org/exit-addresses
resource "aws_wafregional_rule" "idp_waf_rule4_reputation_lists" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule4ReputationLists"
  metric_name = "${var.env_name}IdPWAFRule4ReputationLists"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule4_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule4_ipset" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule4ReputationListsIPSet"
}

# rule 5
# SQL Injection Conditions
resource "aws_wafregional_rule" "idp_waf_rule5_sqli" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule5SQLiConditions"
  metric_name = "${var.env_name}IdPWAFRule5SQLiConditions"

  predicate {
    type    = "SqlInjectionMatch"
    data_id = "${aws_wafregional_sql_injection_match_set.rule5_match_set.id}"
    negated = false
  }
}

resource "aws_wafregional_sql_injection_match_set" "rule5_match_set" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule5SQLiConditionsMatchSet"

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }
  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "BODY"
    }
  }
  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }
  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "URI"
    }
  }
  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }
  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }
}

# rule 6
# XSS conditions
resource "aws_wafregional_rule" "idp_waf_rule6_xss" {
  count       = "${var.enable_waf ? 1 : 0}"
  name        = "${var.env_name}IdPWAFRule6XSSConditions"
  metric_name = "${var.env_name}IdPWAFRule6XSSConditions"

  predicate {
    type    = "XssMatch"
    data_id = "${aws_wafregional_xss_match_set.rule6_match_set.id}"
    negated = false
  }
}

resource "aws_wafregional_xss_match_set" "rule6_match_set" {
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}IdPWAFRule6XSSConditionsMatchSet"
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
  acl    = "private"
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
  count = "${var.enable_waf ? 1 : 0}"
  name  = "${var.env_name}_firehose_waf_role_policy"
  role  = "${aws_iam_role.firehose_role.id}"

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
