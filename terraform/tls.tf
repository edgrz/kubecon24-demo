resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content  = tls_private_key.rsa-4096-example.private_key_pem
  filename = "${path.module}/id_rsa"
}

resource "aws_key_pair" "public_key" {
  key_name   = local.tls_keys_name
  public_key = tls_private_key.rsa-4096-example.public_key_openssh
}