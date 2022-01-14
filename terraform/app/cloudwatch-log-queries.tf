yamldecode(templatefile("cloudwatch-log-queries.yml", {"env" = "frank"}))
{
  "waf/blocked-by-path" = {
    "logs" = [
      "aws-waf-logs-frank-idp-waf",
    ]
    "query" = <<-EOT
    filter action != "ALLOW"
    | stats count() as count by httpRequest.httpMethod,httpRequest.uri
    | sort count desc

    EOT
  }
  "waf/blocked-by-rule-and-ip" = {
    "logs" = [
      "aws-waf-logs-frank-idp-waf",
    ]
    "query" = <<-EOT
    filter action != "ALLOW"
    | stats count() as count by terminatingRuleId,httpRequest.clientIp
    | sort count desc

    EOT
  }
}


resource "aws_cloudwatch_query_definition" "default" {
    for_each = var.queries

    name = "${env}/${key}"
    log_group_names = value.logs
    query_string = value.query
}

