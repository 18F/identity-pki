module "config_access_key_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "config_access_key_rotation.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = var.config_access_key_rotation_code
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "config_access_key_rotation_lambda" {
  filename      = module.config_access_key_rotation_code.zip_output_path
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation_lambda_role.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "config_access_key_rotation.lambda_handler"

  source_code_hash = module.config_access_key_rotation_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      RotationPeriod   = 80,
      InactivePeriod   = 90,
      RetentionPeriod  = 100,
      ENFORCE_DAY      = "July 5th, 2023",
      lambda_temp_role = "${aws_iam_role.assumeRole_lambda.arn}"
    }
  }

  depends_on = [module.config_access_key_rotation_code.resource_check]
}

