module "common_variables" {
  source = "../../modules/common_variables"

  environment = var.environment
}

resource "aws_route53_zone" "main" {
  name = module.common_variables.dns_zone_name

  tags = {
    Environment = var.environment
  }
}