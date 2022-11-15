data "aws_caller_identity" "current" {}

# deploy the all/tooling target to the tooling account on the main branch

module "code_pipeline_alarms" {
  source = "../../modules/code_pipeline_alarms"

  alarm_name           = aws_codepipeline.auto_tf_pipeline.name
  code_pipeline_arn    = aws_codepipeline.auto_tf_pipeline.arn
  enable_autotf_alarms = var.enable_autotf_alarms
  sns_target_arn = join(":", [
    "arn:aws:sns:${var.region}",
    "${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
  ])
}
