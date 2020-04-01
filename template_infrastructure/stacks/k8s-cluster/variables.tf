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

variable "cluster_name" {
  description = "The name of the kubernetes cluster"
  type = string
}

variable "master_instance_type" {

} t2.medium

variable "worker_instance_type" {
} t2.medium

variable "ssh_public_key" {
"~/.ssh/id_rsa.pub"
}
variable "ssh_access_cidr" {
["0.0.0.0/0"]
}

variable "api_access_cidr" {
["0.0.0.0/0"]
}

variable "min_worker_count" {
3
}
variable "max_worker_count" {
6
}
variable "hosted_zone" {
"my-domain.com"

}
variable "hosted_zone_private" {
false
}

# data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
variable "master_subnet_id" {
"subnet-8a3517f8"
}

variable "worker_subnet_ids" {
[
  "subnet-8a3517f8",
  "subnet-9b7853f7",
  "subnet-8g9sdfv8",
]
}

