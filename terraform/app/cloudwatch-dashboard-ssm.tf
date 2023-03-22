resource "aws_cloudwatch_dashboard" "ssm_dashboard" {
  dashboard_name = "${var.env_name}-ssm-dashboard"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 7,
        "y" : 0,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp, detail.userIdentity.principalId, @message, @logStream, @log\n| stats count(*) as Count by detail.requestParameters.documentName as Document\n| sort Count desc\n| limit 20",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "table",
          "title" : "Count of Instances of Document Run"
        }
      },
      {
        "height" : 6,
        "width" : 7,
        "y" : 0,
        "x" : 7,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp, detail.userIdentity.principalId, @message, @logStream, @log\n| stats count(*) as Count by detail.requestParameters.documentName as Document\n| sort Count desc\n| limit 20",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Count of Instances of Document Run",
          "view" : "pie"
        }
      },
      {
        "height" : 6,
        "width" : 7,
        "y" : 6,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp, @message, @logStream, @log, detail.req\n| stats count(*) as Count by substr(detail.userIdentity.principalId,22) as User\n| sort Count desc\n| limit 20",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Count of SSM Usages per User",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 7,
        "y" : 6,
        "x" : 7,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp, @message, @logStream, @log, detail.req\n| stats count(*) as Count by substr(detail.userIdentity.principalId,22) as User\n| sort Count desc\n| limit 20",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Count of SSM Usages per User",
          "view" : "pie"
        }
      },
      {
        "height" : 12,
        "width" : 10,
        "y" : 0,
        "x" : 14,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp, @message, @logStream, @log\n| stats count(*) as Count by substr(detail.userIdentity.principalId, 22) as User, detail.requestParameters.documentName as Document\n| sort User, Count desc\n| limit 100",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Count of Document Run by User",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 12,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-cmds-${var.env_name}' | fields @timestamp as Time, substr(detail.userIdentity.principalId, 22) as User, detail.responseElements.sessionId as SessionId, detail.requestParameters.documentName as Document\n| sort @timestamp desc\n| limit 100",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "table",
          "title" : "Most Recent 100 SSM Commands (within selected timeframe)"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 18,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'aws-ssm-sessions-${var.env_name}' | fields @timestamp as Time, sessionId, target.id, concat(sessionData.0,sessionData.1,sessionData.2,sessionData.3,sessionData.4) as sessionData\n| sort @timestamp desc\n| limit 100",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "table",
          "title" : "Most Recent 100 SSM Sessions (within selected timeframe)"
        }
      }
    ]
  })
}
