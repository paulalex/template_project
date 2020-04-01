variable "environment" {
  description = "The environment that is currently being built"
  type        = string
}

variable "stack_name" {
  description = "The name of the Jenkins stack"
  type        = string
  default     = "jenkins"
}

variable "device_path" {
  description = "The path of the additional EBS volume"
  type        = string
}

variable "jenkins_ami" {
  type = string
  default = "ami-0773391ae604c49a4"
}

variable "jenkins_instance_type" {
  type = string
  default = "t2.medium"
}

variable "jenkins_ebs_tag_name" {
  type = string
  default = "Jenkins Secondary Volume"
}






