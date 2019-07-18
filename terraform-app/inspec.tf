resource "aws_ssm_association" "cis" {
  association_name = "${var.env_name}-Inspec"
  name = "AWS-RunInspecChecks"
  schedule_expression= "cron(0 0 */12 * * ? *)"

  targets {
    key    = "tag:domain"
    values = ["${var.env_name}.${var.root_domain}"]
  }

  parameters {
    sourceType = "GitHub"
    sourceInfo = "{\"owner\":\"18F\",\"repository\":\"cis-dil-benchmark\",\"path\":\"\",\"getOptions\":\"branch:master\"}"
  }
}
