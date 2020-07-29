locals {
  s3_buckets_ue1 = {
    "lambda-functions" = {
      lifecycle_rules    = [
        {
          id          = "inactive"
          enabled     = true
          prefix      = "/"
          transitions = [
            {
              days          = 180
              storage_class = "STANDARD_IA"
            }
          ]
        }
      ],
      force_destroy = false
    }
  }
}

module "s3_shared_ue1" {
  source = "github.com/18F/identity-terraform//s3_bucket_block?ref=5936d2aa33f5835bf7576e74061185cae61da4d9"
  #source = "../../../../identity-terraform/s3_bucket_block"
  providers = {
    aws = aws.us-east-1
  }
  
  region = "us-east-1"
  bucket_prefix = "login-gov"
  bucket_data = local.s3_buckets_ue1
}

# Policy covering uploads to the US-EAST-1 lambda functions bucket
module "s3_policies_ue1" {
  source = "../../modules/shared_bucket_policies"
  providers = {
    aws = aws.us-east-1
  }

  lambda_bucket = module.s3_shared_ue1.buckets["lambda-functions"]
  circleci_arn = aws_iam_user.circleci.arn
}