resource "aws_macie2_account" "account_scan" {
  finding_publishing_frequency = "ONE_HOUR"
  status                       = "ENABLED"
}

resource "aws_macie2_classification_job" "account_bucket_scan" {
  job_type = "SCHEDULED"
  name     = "weekly_bucket_scans"
  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = var.macie_scan_buckets
    }
  }

  sampling_percentage = 100
  schedule_frequency {
    daily_schedule = true
  }

  depends_on = [aws_macie2_account.account_scan]
}

resource "aws_macie2_findings_filter" "account_filter" {
  name        = "Suppress Low/Medium Findings"
  description = "Suppress Low/Medium Findings"
  position    = 1
  action      = "ARCHIVE"
  finding_criteria {
    criterion {
      field = "severity.description"
      eq    = ["Medium", "Low"]
    }
  }
  depends_on = [aws_macie2_account.account_scan]
}

resource "aws_cloudwatch_log_group" "macie2_classification_jobs" {
  name              = "/aws/macie/classificationjobs"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = true
}
