output "enable_vpn_gateway" {
  value       = var.enable_vpn_gateway
  description = "The name of the Auto Scaling Group"
}

output "vpc_terraform_state_key" {
  value       = var.vpc_terraform_state_key
  description = "Terraform remote state key path for VPC"
}