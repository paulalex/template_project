variable "environment" {
  description = "The environment that is currently being built"
}

variable "org_name" {
  default = "ockleford"
}

variable "owner" {
  default = "Paul Ockleford"
}

variable "region" {
  type = string
  default = "eu-west-2"
}

variable "vpc_terraform_state_key" {
  type = string
  default = "vpc/terraform.tfstate"
}

variable "r53_terraform_state_key" {
  type = string
  default = "r53/terraform.tfstate"
}