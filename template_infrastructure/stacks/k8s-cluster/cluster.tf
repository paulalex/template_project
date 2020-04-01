data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = lookup(module.common_variables.terraform_state_s3_bucket, var.environment, "")
    key    = module.common_variables.vpc_terraform_state_key
    region = module.common_variables.aws_region
  }
}

module "common_variables" {
  source = "../../modules/common_variables"

  environment = var.environment
}

module "vpc_variables" {
  source = "../../modules/vpc_variables"

  enable_vpn_gateway = var.enable_vpn_gateway
}

module "kubernetes" {
  source = "github.com/paulalex/terraform-aws-kubernetes"

  aws_region           = module.common_variables.aws_region
  cluster_name         = var.cluster_name
  master_instance_type = "t2.medium"
  worker_instance_type = "t2.medium"
  ssh_public_key       = "~/.ssh/id_rsa.pub"
  ssh_access_cidr      = ["0.0.0.0/0"]
  api_access_cidr      = ["0.0.0.0/0"]
  min_worker_count     = 3
  max_worker_count     = 6
  hosted_zone          = "my-domain.com"
  hosted_zone_private  = false
  # data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
  master_subnet_id = "subnet-8a3517f8"

  worker_subnet_ids = [
    "subnet-8a3517f8",
    "subnet-9b7853f7",
    "subnet-8g9sdfv8",
  ]

  # Tags
  tags = {
    Application = "AWS-Kubernetes"
  }

  # Tags in a different format for Auto Scaling Group
  tags2 = [
    {
      key                 = "Application"
      value               = "AWS-Kubernetes"
      propagate_at_launch = true
    },
  ]

  addons = [
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/storage-class.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/metrics-server.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/dashboard.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/external-dns.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/autoscaler.yaml",
  ]
}