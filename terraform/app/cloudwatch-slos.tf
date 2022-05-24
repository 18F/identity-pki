module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=0fe0243d7df353014c757a72ef0c48f5805fb3d3"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
