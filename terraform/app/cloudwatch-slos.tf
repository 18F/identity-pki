module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
