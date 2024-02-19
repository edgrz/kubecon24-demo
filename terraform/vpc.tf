module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = local.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a"]
  private_subnets = []
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "Testing"
  }
}