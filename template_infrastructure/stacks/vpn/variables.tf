variable "environment" {
  description = "The environment that is currently being built"
  type        = string
}

variable "stack_name" {
  description = "The name of the VPN stack"
  type        = string
  default     = "vpn"
}

variable "device_path" {
  description = "The path of the additional EBS volume"
  type        = string
}

variable "vpn-ami" {
  // AMI ID for VPN in eu-west-2
  type = string
  default = "ami-0d885004ea1a5448e"
}

variable "vpn_instance_type" {
  type = string
}

variable "vpc_terraform_state_key" {
  type = string
  default = "vpc/terraform.tfstate"
}

variable "vpnas_admin_password" {
  type = string
  default = "letmein123"
}

variable "vpn_ebs_tag_name" {
  type = string
  default = "VPN Secondary Volume"
}

variable "vpnas_path" {
  type = string
  default = "/usr/local/openvpn_as"
}

variable "vpnas_admin_dns_name" {
  description = "DNS record name to use for VPNAS admin"
  default = "vpnas-admin"
}

variable "vpnas_client_dns_name" {
  description = "DNS record name to use for VPNAS client"
  default = "vpnas-client"
}





