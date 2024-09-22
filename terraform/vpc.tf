#Import vpc module, create a custom VPC first
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  cidr = var.aws_vpc_cidr_block
  azs  = data.aws_availability_zones.az.names


  private_subnets = [for i in range(var.aws_private_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i)]
  public_subnets  = [for i in range(var.aws_public_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i + 10)]

  enable_nat_gateway = var.aws_enable_nat_gateway # For private subnets to access internet
  enable_vpn_gateway = var.aws_enable_vpn_gateway

  tags = { 
      Name = "VPC-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  }
}