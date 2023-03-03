resource "aws_cloudwatch_dashboard" "ddos_dashboard" {
  dashboard_name = "${var.env_name}-ddos-dashboard"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 12,
        "y" : 0,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-waf-logs-${var.env_name}-idp-waf' | fields httpRequest.clientIp\n| stats count(*) as requestCount by httpRequest.clientIp\n| sort requestCount desc\n",
          "region" : "us-east-1",
          "stacked" : false,
          "title" : "Top Client IPs Logged by CloudFront",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 0,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by src\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "table",
          "title" : "Top Client IPs Logged by Nginx"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 6,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-waf-logs-${var.env_name}-idp-waf' | fields httpRequest.uri\n| stats count() as requestCount by httpRequest.uri\n| sort requestCount desc\n",
          "region" : "us-east-1",
          "stacked" : false,
          "title" : "Top Request Paths Logged by CloudFront",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 6,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by uri_path\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Top Request Paths Logged by Nginx",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 12,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-waf-logs-${var.env_name}-idp-waf' | fields @message\n| parse @message /(?i)\"name\":\"user-agent\",\"value\":\"(?<httpRequestUserAgent>[^\"]+)/\n| sort httpRequestUserAgent desc\n| stats count() as httpRequestUserAgentCount by httpRequestUserAgent\n| sort by httpRequestUserAgentCount desc\n",
          "region" : "us-east-1",
          "stacked" : false,
          "title" : "Top User-Agents Logged by CloudFront",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 12,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by http_user_agent\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Top User-Agents Logged by Nginx",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 18,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-waf-logs-${var.env_name}-idp-waf' | fields terminatingRuleId\n| stats count() as requestCount by terminatingRuleId\n| sort requestCount desc\n",
          "region" : "us-east-1",
          "stacked" : false,
          "title" : "Top Terminating WAF Rules Logged by CloudFront",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 18,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-waf-logs-${var.env_name}-idp-waf' | fields httpRequest.country\n| stats count() as requestCount by httpRequest.country\n| sort requestCount desc\n",
          "region" : "us-east-1",
          "stacked" : false,
          "title" : "Top Requests By Geo Logged by CloudFront",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 24,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter status like /^5/\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by src\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "50X Type Errors by Client IP",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 24,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter status like /^4/\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by src\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "40X Type Errors by Client IP",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 30,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/var/log/nginx/access.log'\n | filter status like /^2/\n | filter @logStream like /^idp/ or @logStream like /^pivcac/\n | stats count() as count by src\n | sort count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "20X Type Responses by Client IP",
          "view" : "table"
        }
      },
    ]
  })
}