module "infra-functions" {
  source = "github.com/18F/identity-terraform//lambda_pipeline?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  #source = "../../../identity-terraform/lambda_pipeline"

  region                            = var.region
  env                               = "account"
  cf_stack_name                     = "infra-functions"
  project_name                      = "infra-functions"
  project_description               = "Deploy identity-infra functions"
  project_template_s3_bucket        = "login-gov.lambda-functions.${data.aws_caller_identity.current.account_id}-us-west-2"
  project_template_object_key       = "circleci/identity-infra-functions/main/identity-infra-functions.zip"
  project_artifacts_s3_bucket       = "login-gov.lambda-functions.894947205914-us-west-2"
  vpc_arn                           = "none"
  pipeline_failure_notification_arn = var.slack_events_sns_hook_arn
}
