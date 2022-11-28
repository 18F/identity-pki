module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
