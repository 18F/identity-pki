module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=e088c86308b757e37b608ae54b6e7b5f3e7075a3"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
