data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "common_variables" {
  source = "../../../modules/common_variables"

  environment = var.environment
}

module "vpc_variables" {
  source = "../../../modules/vpc_variables"

  enable_vpn_gateway = var.enable_vpn_gateway
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  private_subnets = [
    for i, entry in data.aws_availability_zones.available.names :
    cidrsubnet(module.common_variables.vpc_cidr, 8, i)
  ]
  public_subnets = [
    for i, entry in data.aws_availability_zones.available.names :
    cidrsubnet(module.common_variables.vpc_cidr, 8, 100 + i)
  ]
}

module "vpc" {
  source = "../../../modules/vpc"

  name = "${var.environment}-${var.vpc_name}"

  cidr = module.common_variables.vpc_cidr

  azs                 = data.aws_availability_zones.available.names
  private_subnets     = length(local.private_subnets) > 2 ? slice(local.private_subnets, 0, 3) : local.private_subnets
  public_subnets      = length(local.public_subnets) > 2 ? slice(local.public_subnets, 0, 3) : local.public_subnets

//  azs                 = module.common_variables.azs
//  private_subnets     = module.common_variables.private_subnets
//  public_subnets      = module.common_variables.public_subnets

  enable_ipv6 = true
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  # VPC endpoint for S3
  enable_s3_endpoint = true

  # VPC endpoint for DynamoDB
  enable_dynamodb_endpoint = true

  tags = {
    Owner       = module.common_variables.owner
    Environment = module.common_variables.environment
    Name        = "template"
  }

  public_subnet_tags = {
    Name = "public-subnet"
  }

  private_subnet_tags = {
    Name = "private-subnet"
  }

  vpc_tags = {
    Name = "${var.environment}-vpc-name"
  }

  private_route_table_tags = {
    Name = "${var.environment}-private-route-table"
  }
}
