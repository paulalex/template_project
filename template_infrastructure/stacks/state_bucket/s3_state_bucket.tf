module "common_variables" {
  source = "../../modules/common_variables"

  environment = var.environment
}

resource "aws_s3_bucket" "remote_state_bucket" {
  bucket = "ockleford-${var.environment}-terraform-remote-state"
}