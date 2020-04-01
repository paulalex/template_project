variable "enable_vpn_gateway" {
  description = "Should VPN gateway be turned on for the VPC"
  type        = string
  default     = false
}

variable "vpc_terraform_state_key" {
  description = "Terraform remote state key path for VPC"
  type        = string
  default     = "vpc/terraform.tfstate"
}