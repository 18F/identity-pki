# The WAF acts as an ingress firewall for everything in our VPC.

# The configuration here does not set up WAF ACLs.  Terraform does not support
# WAF Regional ACLs.
resource "null_resource" "associate_idp_acl" {
  depends_on = ["aws_alb.idp"]
  count      = "${var.enable_legacy_waf ? 1 : 0}"

  # Re-associate whenever the ALB ARN or ACL ID change.
  triggers {
    idp_alb = "${aws_alb.idp.arn}"
    acl_id  = "${var.idp_web_acl_id}"
  }
  provisioner "local-exec" {
    command = "aws waf-regional associate-web-acl --web-acl-id ${var.idp_web_acl_id} --resource-arn ${aws_alb.idp.arn}"
  }
  # The following "destroy"-time provisioner is only legal in Terraform 0.9.
  # Uncomment the following when we retire 0.8.  Until then, the Terraform
  # configuration will not properly handle changing var.enable_waf from true
  # to false, but it will properly handle an ALB destroy/recreation.
  # You can remove associations by hand at
  # https://console.aws.amazon.com/waf/home?region=us-west-2#/webacls/rules/eb5d2b12-a361-4fa0-88f2-8f632f6a9819
  #
  provisioner "local-exec" {
    when = "destroy"
    command = "aws waf-regional disassociate-web-acl --resource-arn ${aws_alb.idp.arn}"

    # If var.enable_waf is true, this provisioner is being run because the
    # IDP ALB changed.  It's not strictly necessary to disassociate the web
    # ACL from the ALB; this is done implicitly when the ALB is removed, so
    # we don't care if this fails.
    #
    # If var.enable_waf is false, this provisioner is being run because of
    # this change.  It's more important that the provisioner fail here so that
    # we don't end up running with a web ACL still attached to an ALB
    # improperly.  If you encounter problems as a result of this, an easy fix
    # is just to taint aws_alb.idp.
    on_failure = "fail"
  }
}

resource "aws_wafregional_web_acl" "idp_web_acl" {
  depends_on  = ["aws_alb.idp"]
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

###############
# rules and ip sets
###############

# rule 1
# IP based passlist
resource "aws_wafregional_rule" "idp_waf_rule1_passlist" {
  name        = "IdPWAFRule1"
  metric_name = "IdPWAFRule1"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule1_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule1_ipset" {
  name = "IdPWAFRule1IPSet"

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
  name        = "IdPWAFRule2"
  metric_name = "IdPWAFRule2"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule2_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule2_ipset" {
  name = "IdPWAFRule2BlocklistIPSet"
}

# rule 3
# IP based bad bots blocklist
resource "aws_wafregional_rule" "idp_waf_rule3_bad_bots" {
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
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule4_ipset" {
  name = "IdPWAFRule4IPSet"
}

# rule 5
# IP Reputation List from https://rules.emergingthreats.net/
# https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt
resource "aws_wafregional_rule" "idp_waf_rule5_" {
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule5_ipset" {
  name = "IdPWAFRule4IPSet"
}

# rule 6
# Tor exit points from https://check.torproject.org/exit-addresses
resource "aws_wafregional_rule" "idp_waf_rule6_" {
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule6_ipset" {
  name = "IdPWAFRule4IPSet"
}

# rule 7
# SQL Injection Conditions
resource "aws_wafregional_rule" "idp_waf_rule7_" {
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule7_ipset" {
  name = "IdPWAFRule4IPSet"
}

# rule 8
# XSS conditions
resource "aws_wafregional_rule" "idp_waf_rule8_" {
  name        = "IdPWAFRule4BadBots"
  metric_name = "IdPWAFRule4BadBots"

  predicate {
    type    = "IPMatch"
    data_id = "${aws_wafregional_ipset.rule3_ipset.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "rule8_ipset" {
  name = "IdPWAFRule4IPSet"
}

###############
# logging
###############
resource "aws_kinesis_firehose_delivery_stream" "waf_s3_stream" {
  name        = "aws-waf-logs-${var.env_name}-idp-waf-firehose-s3-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.waf_logbucket.arn}"
  }
}

resource "aws_s3_bucket" "waf_logbucket" {
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
  name = "${var.env_name}_firehose_waf_role"

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
