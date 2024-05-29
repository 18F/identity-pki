variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "source_account_id" {
  type        = string
  description = <<EOM
ID of the AWS account that will be sending logs to the CloudWatch Logs Destinations /
Kinesis Firehose in this account.
EOM
}

variable "secondary_region" {
  type        = string
  description = <<EOM
Secondary region where CloudWatch Destinations exist, which will be
sending to the Kinesis Data Stream/Firehose in this region.
Leave BLANK to disable creation of resources in the secondary region.
EOM
  default     = ""
}

variable "enable_s3_replication" {
  type        = bool
  description = <<EOM
Whether or not to enable S3 Replication on the login-gov.logarchive-sandbox bucket,
copying from us-west-2 to us-east-1. Will create replica bucket, and associated
resources, if set to 'true'.
EOM
  default     = false
}

variable "log_record_s3_keys" {
  type        = string
  description = <<EOM
If set to 'YES', will print out the name of each object added to S3 by the
logarchive_kinesis Lambda function. Each object is of the format:
CloudWatchLogs/ACCTNUM/REGION/SOURCESERVICE/GROUP/STREAM/PARTITIONKEY-SEQUENCENUMBER
EOM
  default     = "NO"
}