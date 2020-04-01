output "aws_region" {
  value = var.region
}

output "org_name" {
  value = var.org_name
}

output "owner" {
  value = var.owner
}

output "dns_zone_name" {
  value = "${var.environment}.ockleford-platform.uk"
}

output "environment" {
  value = var.environment
}

output "terraform_state_s3_bucket" {
  value = {
    dev: "${var.org_name}-${var.environment}-terraform-remote-state"
  }
}

output "vpc_cidr" {
  value = "10.0.0.0/16"
}

output "azs" {
  value       = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  description = "Supported Availability Zones"
}

output "private_subnets" {
  value       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "Private Subnet Ranges"
}

output "public_subnets" {
  value       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  description = "Public Subnet Ranges"
}

output "vpc_terraform_state_key" {
  description = "The key for the VPC remove state"
  value = var.vpc_terraform_state_key
}