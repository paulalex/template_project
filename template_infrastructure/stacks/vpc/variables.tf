variable "enable_vpn_gateway" {
  description = "Should VPN gateway be turned on for the VPC"
  type        = string
  default     = false
}

variable "environment" {
  description = "The environment that is currently being built"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}