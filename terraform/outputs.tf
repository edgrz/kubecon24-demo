output "ssh_command_proxy" {
  value = "ssh -i ${path.module}/id_rsa ubuntu@${module.ec2_proxy.public_ip}"
}

output "ssh_command_kind" {
  value = "ssh -i ${path.module}/id_rsa ubuntu@${module.ec2_kind.public_ip} -L 6443:localhost:6443"
}

output "kubeconfig" {
  value = "ssh -i ${path.module}/id_rsa ubuntu@${module.ec2_kind.public_ip} sudo cat /install/data/${local.machine_kind_name}.config"
}