resource "aws_ssm_association" "cis" {
  name = "AWS-RunInspecChecks"
  schedule_expression= "cron(0 0 */12 * * ? *)"

  targets {
    key    = "tag:prefix"
    values = ["idp","jumphost","app","outboundproxy","elk","elasticsearch","pivcac"]
  }

  parameters {
    sourceType = "GitHub"
    sourceInfo = "{\"owner\":\"18F\",\"repository\":\"cis-dil-benchmark\",\"path\":\"\",\"getOptions\":\"branch:crissupb/updates\"}"
  }

}
