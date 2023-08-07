resource "aws_cloudwatch_event_rule" "rds_az_failover" {
  name        = "${var.env_name}-rds-az-failover"
  description = "Capture RDS Failover Events"

  event_pattern = jsonencode(
    {
      "detail-type" : ["RDS DB Cluster Event"],
      "source" : ["aws.rds"],
      "resources" : ["${module.idp_aurora_uw2.cluster_arn}"],
      "detail" : {
        "EventCategories" : ["failover"]
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "rds_az_failover" {
  rule      = aws_cloudwatch_event_rule.rds_az_failover.name
  target_id = "SendRDSFailOverEventsToSlackViaSNS"
  arn       = var.slack_events_sns_hook_arn

  input_transformer {
    input_paths = {
      name          = "$.detail.Tags.Name",
      region        = "$.region",
      time_of_issue = "$.time",
      detail        = "$.detail.Message",
    }
    input_template = "\"RDS Cluster <name> <detail> Region: <region> Time: <time_of_issue>\""
  }
}

resource "aws_cloudwatch_event_rule" "rds_global_failover" {
  name        = "${var.env_name}-rds-global-failover"
  description = "Capture RDS Failover Events"

  event_pattern = jsonencode(
    {
      "detail-type" : ["RDS DB Cluster Event"],
      "source" : ["aws.rds"],
      "resources" : ["${module.idp_aurora_uw2.cluster_arn}"],
      "detail" : {
        "EventCategories" : ["global-failover"]
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "rds_global_failover" {
  rule      = aws_cloudwatch_event_rule.rds_global_failover.name
  target_id = "SendRDSFailOverEventsToSlackViaSNS"
  arn       = var.slack_events_sns_hook_arn

  input_transformer {
    input_paths = {
      name          = "$.detail.Tags.Name",
      region        = "$.region",
      time_of_issue = "$.time",
      detail        = "$.detail.Message",
    }
    input_template = "\"RDS Cluster <name> <detail> Region: <region> Time: <time_of_issue>\""
  }
}