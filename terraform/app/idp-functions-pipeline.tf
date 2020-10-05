module "idp-lambda-functions" {
  source = "github.com/18F/identity-terraform//lambda_pipeline?ref=bdd8ad5ff0ea0fcb4be1b8aab7cc206e0dfdded2"

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
