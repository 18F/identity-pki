module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=ba96a78a026a5ac77deecd7e6e6c615970a389f2"
  #source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
