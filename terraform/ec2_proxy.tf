module "sg_proxy" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = local.machine_proxy_name
  description = "Security group that is attached to the node used for demo-ing purposes"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "Access to EC2 instance via SSH"
      cidr_blocks = "196.3.50.0/24"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "Access to EC2 instance via SSH"
      cidr_blocks = "${chomp(data.http.myip.body)}/32" # my actual public ip
    },
    {
      from_port   = 3128
      to_port     = 3128
      protocol    = "TCP"
      description = "Access from kind kubernetes cluster to HTTP proxy"
      cidr_blocks = "${module.ec2_kind.public_ip}/32" # Allow ingress traffic to the proxy port from the kind EC2 instance
    },
  ]

  ######### Allow ALL egress traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow ALL egress"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}


module "ec2_proxy" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  # Needs ec2_kind to be created first, as needs to configure a SG to allow incoming traffic from it
  depends_on = [
    module.ec2_kind
  ]

  name = local.machine_proxy_name

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "m5.xlarge"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.sg_proxy.security_group_id]
  associate_public_ip_address = true

  key_name = aws_key_pair.public_key.key_name

  user_data_base64            = base64encode(file("${path.module}/user_data_proxy.sh"))
  user_data_replace_on_change = true

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 512
    },
  ]
}