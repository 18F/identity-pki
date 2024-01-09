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
