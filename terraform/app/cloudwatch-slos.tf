module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=f9cee1ae41992f37b5d157f6c3dbcc70f395aaa2"
  # source = "../../../identity-terraform/slo_lambda"
  name  = "${var.env_name}-cloudwatch-sli"
  count = var.enable_cloudwatch_slos ? 1 : 0
  providers = {
    aws = aws.usw2
  }

  load_balancer_arn = aws_alb.idp.arn
  sli_namespace     = "${var.env_name}/sli"
}
