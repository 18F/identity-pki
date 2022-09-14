# exportcloudwatchlogstos3

This module creates an export task for exporting an existing cloudwatch log group to S3 bucket. 
- Logs can be pushed to an existing bucket or a new one. If encryption enabled in buckets, be sure that you're using a supported type of server-side encryption. Exporting to S3 buckets encrypted with SSE-KMS is not supported. Exporting to S3 buckets that are encrypted with AES-256 is supported.
- Lambda creates a SSM parameter and stores the "time" in epoch when a export task is successfully completed for a reference for next export task for the same log group, in order to avoid duplication.
- The CloudWatch Logs service quota allows only one running or pending export task per account per Region. This quota can't be changed. Thus, lambda will have a single export task running at one time. If multiple log groups are passed to lambda, either increase the execution timeout value for lambda or run lambda frequently.



## Architecture Diagram: Export Cloudwatch Logs to S3

![Export logs](./export.png)

## Usage:

    module "export_to_s3" {
        source                        = "/identity-devops/terraform/modules/export_cwlogs_to_s3"
	    cw_log_group                  = var.cw_log_group
        region                        = var.region
        s3_bucket                     = var.s3_bucket

    }
