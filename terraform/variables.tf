variable "env_name" {
  description = "The name of the environment"
  type        = string
  default     = "demo"
}

variable "cidr" {
  description = "The CIDR to be used for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

locals {
  machine_kind_name  = "kubecon-kind-${var.env_name}"
  machine_proxy_name = "kubecon-proxy-${var.env_name}"
  vpc_name           = "kubecon-${var.env_name}"
  tls_keys_name      = "kubecon-${var.env_name}"
}

# get my poublic ip to configure EC2 SG (incoming) via SSH
data "http" "myip" {
  url = "http://checkip.amazonaws.com"
}

# AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}