module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=7e18b31a0dc6560b3000e4d2792d000a9c9976b8"
  #source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
