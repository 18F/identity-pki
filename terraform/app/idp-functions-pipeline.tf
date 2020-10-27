module "idp-lambda-functions" {
  source = "github.com/18F/identity-terraform//lambda_pipeline?ref=1604e4f20ebb71e17737685b83b0028ec4504782"
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
}
