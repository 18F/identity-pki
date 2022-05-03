module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=4e19868ad1ed9ab3fa6b9938eb85c97db3b8a0a7"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
