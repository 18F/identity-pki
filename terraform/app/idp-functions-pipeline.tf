module "idp-lambda-functions" {
  source = "github.com/18F/identity-terraform//lambda_pipeline?ref=fa629ba4e32e1439e8f77b37da4c785093113318"

  region = var.region
  env = var.env_name
  cf_stack_name = "idp-functions"
  project_name = "idp-functions"
  project_description = "Deploy idp functions"
  project_source_s3_bucket = "login-gov.lambda-functions.894947205914-us-west-2"
  project_source_object_key = "circleci/identity-idp-functions/master/identity-idp-functions.zip"
  parameter_application_functions = "${var.env_name}/idp/lambda/application-functions"
  vpc_arn = aws_vpc.default.arn
}
