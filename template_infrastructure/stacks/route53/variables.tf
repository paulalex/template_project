variable "environment" {
  description = "The environment that is currently being built"
  type        = string
}

variable "stack_name" {
  description = "The name of the VPN stack"
  type        = string
  default     = "r53"
}