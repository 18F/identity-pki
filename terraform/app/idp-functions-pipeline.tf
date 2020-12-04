module "idp-lambda-functions" {
  source = "github.com/18F/identity-terraform//lambda_pipeline?ref=44ea510288631f0e20786f2cfa2f1eb1e9f6898c"
  #source = "../../../identity-terraform/lambda_pipeline"

  region = var.region
  env = var.env_name
  cf_stack_name = "idp-functions"
  project_name = "idp-functions"
  project_description = "Deploy idp functions"
  project_template_s3_bucket = "login-gov.lambda-functions.${data.aws_caller_identity.current.account_id}-us-west-2"
  project_template_object_key = "circleci/identity-idp-functions/master/identity-idp-functions.zip"
  project_artifacts_s3_bucket = "login-gov.lambda-functions.894947205914-us-west-2"
  parameter_application_functions = "${var.env_name}/idp/lambda/application-functions"
  vpc_arn = aws_vpc.default.arn
  pipeline_failure_notification_arn = var.slack_events_sns_hook_arn
}
