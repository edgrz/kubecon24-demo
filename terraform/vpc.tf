// List of availability zones for the chosen region.
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name            = local.vpc_name
  cidr            = var.cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = []
  public_subnets = [
    for i, v in data.aws_availability_zones.available.names :
    cidrsubnet(var.cidr, 8, 100 + i)
  ]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "Testing"
  }
}