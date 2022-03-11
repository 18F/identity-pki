module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
