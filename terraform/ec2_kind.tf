module "sg_kind" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = local.machine_kind_name
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

  ####### Allow ONLY egress traffic to the EC2 Proxy (+ DNS and NTP)
  # egress_with_cidr_blocks = [
  #   {
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     description = "Access to Proxy VM"
  #     cidr_blocks = "${module.ec2_proxy.public_ip}/32"
  #   },
  #   {
  #     from_port   = 53
  #     to_port     = 53
  #     protocol    = "TCP"
  #     description = "Access to DNS servers"
  #     cidr_blocks = "0.0.0.0/0"
  #   },
  #   {
  #     from_port   = 53
  #     to_port     = 53
  #     protocol    = "UDP"
  #     description = "Access to DNS servers"
  #     cidr_blocks = "0.0.0.0/0"
  #   },
  #   {
  #     from_port   = 123
  #     to_port     = 123
  #     protocol    = "UDP"
  #     description = "NTP Server (for Talos, if machine.time.disabled=true, this egress rule is not needed)"
  #     cidr_blocks = "0.0.0.0/0"
  #   },
  # ]
}


module "ec2_kind" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  name = local.machine_kind_name

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "m5.xlarge"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.sg_kind.security_group_id]
  associate_public_ip_address = true

  key_name = aws_key_pair.public_key.key_name

  user_data_base64 = base64encode(templatefile("${path.module}/user_data_kind.sh", {
    kind_cluster_name = local.machine_kind_name
    }
  ))
  user_data_replace_on_change = true

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 512
    },
  ]
}
